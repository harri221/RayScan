"""
RayScan ML Model - Training Script
Complete training pipeline for kidney stone detection
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow import keras
from pathlib import Path
from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
import matplotlib.pyplot as plt
import seaborn as sns
from tqdm import tqdm
import json
import argparse

from preprocessing import UltrasoundPreprocessor, DataAugmentor
from models import CustomCNN, VGG16FeatureExtractor, EndToEndCNN, HybridClassifier


def load_dataset(data_dir, preprocessor, for_vgg=False):
    """
    Load and preprocess dataset.

    Args:
        data_dir: Path to dataset directory (with stone/ and normal/ subdirs)
        preprocessor: UltrasoundPreprocessor instance
        for_vgg: Whether to prepare for VGG16 (3 channels)

    Returns:
        X: Preprocessed images
        y: Labels (1=stone, 0=normal)
    """
    data_path = Path(data_dir)

    images = []
    labels = []

    # Load stone images
    stone_dir = data_path / 'stone'
    if stone_dir.exists():
        stone_files = list(stone_dir.glob('*.[jp][pn][g]')) + list(stone_dir.glob('*.jpeg'))
        print(f"Found {len(stone_files)} stone images")

        for img_path in tqdm(stone_files, desc="Loading stone images"):
            try:
                if for_vgg:
                    img = preprocessor.preprocess_for_vgg(img_path)
                else:
                    img = preprocessor.preprocess_single(img_path)
                images.append(img)
                labels.append(1)  # Stone = 1
            except Exception as e:
                print(f"Error loading {img_path}: {e}")

    # Load normal images
    normal_dir = data_path / 'normal'
    if normal_dir.exists():
        normal_files = list(normal_dir.glob('*.[jp][pn][g]')) + list(normal_dir.glob('*.jpeg'))
        print(f"Found {len(normal_files)} normal images")

        for img_path in tqdm(normal_files, desc="Loading normal images"):
            try:
                if for_vgg:
                    img = preprocessor.preprocess_for_vgg(img_path)
                else:
                    img = preprocessor.preprocess_single(img_path)
                images.append(img)
                labels.append(0)  # Normal = 0
            except Exception as e:
                print(f"Error loading {img_path}: {e}")

    X = np.array(images)
    y = np.array(labels)

    # Add channel dimension for grayscale
    if not for_vgg and len(X.shape) == 3:
        X = np.expand_dims(X, axis=-1)

    print(f"\nDataset loaded: {len(X)} images")
    print(f"  - Stone: {np.sum(y == 1)}")
    print(f"  - Normal: {np.sum(y == 0)}")
    print(f"  - Shape: {X.shape}")

    return X, y


def train_hybrid_model(X_train, y_train, X_val, y_val, feature_extractor='cnn', classifier='xgboost'):
    """
    Train hybrid CNN + XGBoost/RF model.

    Args:
        X_train, y_train: Training data
        X_val, y_val: Validation data
        feature_extractor: 'cnn' or 'vgg16'
        classifier: 'xgboost' or 'random_forest'

    Returns:
        Trained HybridClassifier
    """
    print(f"\n{'='*60}")
    print(f"Training Hybrid Model: {feature_extractor.upper()} + {classifier.upper()}")
    print(f"{'='*60}")

    model = HybridClassifier(
        feature_extractor=feature_extractor,
        classifier=classifier
    )

    metrics = model.train(X_train, y_train, X_val, y_val)
    print(f"Training accuracy: {metrics['train_accuracy']:.4f}")

    # Validation metrics
    val_pred = model.predict(X_val)
    val_proba = model.predict_proba(X_val)[:, 1]

    val_acc = np.mean(val_pred == y_val)
    val_auc = roc_auc_score(y_val, val_proba)

    print(f"Validation accuracy: {val_acc:.4f}")
    print(f"Validation AUC: {val_auc:.4f}")

    print("\nClassification Report:")
    print(classification_report(y_val, val_pred, target_names=['Normal', 'Stone']))

    return model, {'val_accuracy': val_acc, 'val_auc': val_auc}


def train_end_to_end_model(X_train, y_train, X_val, y_val, epochs=50, batch_size=32):
    """
    Train end-to-end CNN model.

    Args:
        X_train, y_train: Training data
        X_val, y_val: Validation data
        epochs: Number of epochs
        batch_size: Batch size

    Returns:
        Trained EndToEndCNN
    """
    print(f"\n{'='*60}")
    print("Training End-to-End CNN")
    print(f"{'='*60}")

    model = EndToEndCNN(input_shape=X_train.shape[1:])

    history = model.train(X_train, y_train, X_val, y_val, epochs=epochs, batch_size=batch_size)

    # Validation metrics
    val_pred = (model.predict(X_val) > 0.5).astype(int).flatten()
    val_proba = model.predict(X_val).flatten()

    val_acc = np.mean(val_pred == y_val)
    val_auc = roc_auc_score(y_val, val_proba)

    print(f"\nValidation accuracy: {val_acc:.4f}")
    print(f"Validation AUC: {val_auc:.4f}")

    print("\nClassification Report:")
    print(classification_report(y_val, val_pred, target_names=['Normal', 'Stone']))

    return model, history, {'val_accuracy': val_acc, 'val_auc': val_auc}


def cross_validate(X, y, n_folds=5, model_type='hybrid_cnn_xgboost'):
    """
    Perform k-fold cross-validation.

    Args:
        X, y: Dataset
        n_folds: Number of folds
        model_type: Model to evaluate

    Returns:
        Cross-validation results
    """
    print(f"\n{'='*60}")
    print(f"{n_folds}-Fold Cross-Validation: {model_type}")
    print(f"{'='*60}")

    skf = StratifiedKFold(n_splits=n_folds, shuffle=True, random_state=42)

    accuracies = []
    aucs = []

    for fold, (train_idx, val_idx) in enumerate(skf.split(X, y), 1):
        print(f"\nFold {fold}/{n_folds}")

        X_train, X_val = X[train_idx], X[val_idx]
        y_train, y_val = y[train_idx], y[val_idx]

        if model_type.startswith('hybrid'):
            parts = model_type.split('_')
            fe = parts[1]  # cnn or vgg16
            clf = parts[2]  # xgboost or rf

            model = HybridClassifier(feature_extractor=fe, classifier=clf)
            model.train(X_train, y_train)

            val_pred = model.predict(X_val)
            val_proba = model.predict_proba(X_val)[:, 1]
        else:
            model = EndToEndCNN(input_shape=X.shape[1:])
            model.train(X_train, y_train, X_val, y_val, epochs=30, batch_size=32)

            val_pred = (model.predict(X_val) > 0.5).astype(int).flatten()
            val_proba = model.predict(X_val).flatten()

        acc = np.mean(val_pred == y_val)
        auc = roc_auc_score(y_val, val_proba)

        accuracies.append(acc)
        aucs.append(auc)

        print(f"  Accuracy: {acc:.4f}, AUC: {auc:.4f}")

    print(f"\n{'='*40}")
    print(f"Cross-Validation Results:")
    print(f"  Accuracy: {np.mean(accuracies):.4f} (+/- {np.std(accuracies):.4f})")
    print(f"  AUC: {np.mean(aucs):.4f} (+/- {np.std(aucs):.4f})")

    return {
        'accuracies': accuracies,
        'aucs': aucs,
        'mean_accuracy': np.mean(accuracies),
        'std_accuracy': np.std(accuracies),
        'mean_auc': np.mean(aucs),
        'std_auc': np.std(aucs)
    }


def plot_training_history(history, save_path=None):
    """Plot training history."""
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))

    # Accuracy
    axes[0].plot(history.history['accuracy'], label='Train')
    axes[0].plot(history.history['val_accuracy'], label='Validation')
    axes[0].set_title('Model Accuracy')
    axes[0].set_xlabel('Epoch')
    axes[0].set_ylabel('Accuracy')
    axes[0].legend()
    axes[0].grid(True)

    # Loss
    axes[1].plot(history.history['loss'], label='Train')
    axes[1].plot(history.history['val_loss'], label='Validation')
    axes[1].set_title('Model Loss')
    axes[1].set_xlabel('Epoch')
    axes[1].set_ylabel('Loss')
    axes[1].legend()
    axes[1].grid(True)

    plt.tight_layout()

    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches='tight')
        print(f"Training history saved to: {save_path}")

    plt.show()


def plot_confusion_matrix(y_true, y_pred, save_path=None):
    """Plot confusion matrix."""
    cm = confusion_matrix(y_true, y_pred)

    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                xticklabels=['Normal', 'Stone'],
                yticklabels=['Normal', 'Stone'])
    plt.title('Confusion Matrix')
    plt.xlabel('Predicted')
    plt.ylabel('Actual')

    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches='tight')
        print(f"Confusion matrix saved to: {save_path}")

    plt.show()


def main(args):
    """Main training pipeline."""
    print("="*60)
    print("RayScan ML Model Training Pipeline")
    print("Kidney Stone Detection from Ultrasound Images")
    print("="*60)

    # Create output directories
    models_dir = Path('../models')
    models_dir.mkdir(exist_ok=True)

    # Initialize preprocessor
    preprocessor = UltrasoundPreprocessor(target_size=(224, 224))

    # Load dataset
    print("\n[1/5] Loading Dataset...")
    X, y = load_dataset(
        args.data_dir,
        preprocessor,
        for_vgg=(args.model == 'vgg16_xgboost')
    )

    # Split dataset
    print("\n[2/5] Splitting Dataset...")
    X_train, X_temp, y_train, y_temp = train_test_split(
        X, y, test_size=0.3, stratify=y, random_state=42
    )
    X_val, X_test, y_val, y_test = train_test_split(
        X_temp, y_temp, test_size=0.5, stratify=y_temp, random_state=42
    )

    print(f"  Train: {len(X_train)} images")
    print(f"  Validation: {len(X_val)} images")
    print(f"  Test: {len(X_test)} images")

    # Train model
    print("\n[3/5] Training Model...")

    results = {}

    if args.model == 'cnn_xgboost':
        model, metrics = train_hybrid_model(
            X_train, y_train, X_val, y_val,
            feature_extractor='cnn',
            classifier='xgboost'
        )
        results['cnn_xgboost'] = metrics

    elif args.model == 'vgg16_xgboost':
        model, metrics = train_hybrid_model(
            X_train, y_train, X_val, y_val,
            feature_extractor='vgg16',
            classifier='xgboost'
        )
        results['vgg16_xgboost'] = metrics

    elif args.model == 'end_to_end':
        model, history, metrics = train_end_to_end_model(
            X_train, y_train, X_val, y_val,
            epochs=args.epochs,
            batch_size=args.batch_size
        )
        results['end_to_end'] = metrics

        # Plot training history
        plot_training_history(history, models_dir / 'training_history.png')

    elif args.model == 'all':
        # Train all models for comparison
        print("\nTraining all models for comparison...")

        # CNN + XGBoost
        model_cnn, metrics_cnn = train_hybrid_model(
            X_train, y_train, X_val, y_val,
            feature_extractor='cnn',
            classifier='xgboost'
        )
        results['cnn_xgboost'] = metrics_cnn
        model_cnn.save(str(models_dir / 'cnn_xgboost'))

        # VGG16 + XGBoost (need to reload for 3 channels)
        X_vgg, y_vgg = load_dataset(args.data_dir, preprocessor, for_vgg=True)
        X_train_vgg, X_temp_vgg, y_train_vgg, y_temp_vgg = train_test_split(
            X_vgg, y_vgg, test_size=0.3, stratify=y_vgg, random_state=42
        )
        X_val_vgg, X_test_vgg, y_val_vgg, y_test_vgg = train_test_split(
            X_temp_vgg, y_temp_vgg, test_size=0.5, stratify=y_temp_vgg, random_state=42
        )

        model_vgg, metrics_vgg = train_hybrid_model(
            X_train_vgg, y_train_vgg, X_val_vgg, y_val_vgg,
            feature_extractor='vgg16',
            classifier='xgboost'
        )
        results['vgg16_xgboost'] = metrics_vgg
        model_vgg.save(str(models_dir / 'vgg16_xgboost'))

        # End-to-End CNN
        model_e2e, history_e2e, metrics_e2e = train_end_to_end_model(
            X_train, y_train, X_val, y_val,
            epochs=args.epochs,
            batch_size=args.batch_size
        )
        results['end_to_end'] = metrics_e2e
        model_e2e.model.save(str(models_dir / 'end_to_end_cnn.keras'))

        # Find best model
        best_model = max(results.items(), key=lambda x: x[1]['val_accuracy'])
        print(f"\n{'='*60}")
        print(f"Best Model: {best_model[0]} (Accuracy: {best_model[1]['val_accuracy']:.4f})")
        print(f"{'='*60}")

        model = model_cnn if best_model[0] == 'cnn_xgboost' else (
            model_vgg if best_model[0] == 'vgg16_xgboost' else model_e2e
        )

    # Test evaluation
    print("\n[4/5] Evaluating on Test Set...")

    if hasattr(model, 'predict_proba'):
        test_pred = model.predict(X_test)
        test_proba = model.predict_proba(X_test)[:, 1]
    else:
        test_pred = (model.predict(X_test) > 0.5).astype(int).flatten()
        test_proba = model.predict(X_test).flatten()

    test_acc = np.mean(test_pred == y_test)
    test_auc = roc_auc_score(y_test, test_proba)

    print(f"\nTest Results:")
    print(f"  Accuracy: {test_acc:.4f}")
    print(f"  AUC: {test_auc:.4f}")
    print("\nClassification Report:")
    print(classification_report(y_test, test_pred, target_names=['Normal', 'Stone']))

    # Plot confusion matrix
    plot_confusion_matrix(y_test, test_pred, models_dir / 'confusion_matrix.png')

    # Save model
    print("\n[5/5] Saving Model...")
    if hasattr(model, 'save'):
        model.save(str(models_dir / args.model))
    else:
        model.model.save(str(models_dir / f'{args.model}.keras'))

    # Save results
    results['test_accuracy'] = float(test_acc)
    results['test_auc'] = float(test_auc)

    with open(models_dir / 'results.json', 'w') as f:
        json.dump(results, f, indent=2)

    print(f"\nResults saved to: {models_dir / 'results.json'}")
    print("\nTraining Complete!")

    return model, results


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Train kidney stone detection model')
    parser.add_argument('--data_dir', type=str, default='../data/processed',
                       help='Path to processed dataset')
    parser.add_argument('--model', type=str, default='cnn_xgboost',
                       choices=['cnn_xgboost', 'vgg16_xgboost', 'end_to_end', 'all'],
                       help='Model type to train')
    parser.add_argument('--epochs', type=int, default=50,
                       help='Number of epochs (for end_to_end)')
    parser.add_argument('--batch_size', type=int, default=32,
                       help='Batch size')
    parser.add_argument('--cross_validate', action='store_true',
                       help='Perform cross-validation')

    args = parser.parse_args()
    main(args)

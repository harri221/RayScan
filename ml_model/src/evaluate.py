"""
RayScan ML Model - Evaluation Metrics
Comprehensive evaluation for kidney stone detection model
"""

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    roc_auc_score, roc_curve, precision_recall_curve, average_precision_score,
    confusion_matrix, classification_report
)
from pathlib import Path


class ModelEvaluator:
    """
    Comprehensive model evaluation for medical image classification.
    """

    def __init__(self, model, class_names=['Normal', 'Stone']):
        """
        Initialize evaluator.

        Args:
            model: Trained model with predict() method
            class_names: Names for classes
        """
        self.model = model
        self.class_names = class_names
        self.results = {}

    def evaluate(self, X_test, y_test):
        """
        Run full evaluation on test set.

        Args:
            X_test: Test images
            y_test: Test labels

        Returns:
            Dictionary of metrics
        """
        # Get predictions
        if hasattr(self.model, 'predict_proba'):
            y_pred = self.model.predict(X_test)
            y_proba = self.model.predict_proba(X_test)[:, 1]
        else:
            y_proba = self.model.predict(X_test).flatten()
            y_pred = (y_proba > 0.5).astype(int)

        # Calculate metrics
        self.results = {
            'accuracy': accuracy_score(y_test, y_pred),
            'precision': precision_score(y_test, y_pred),
            'recall': recall_score(y_test, y_pred),  # Sensitivity
            'specificity': self._specificity(y_test, y_pred),
            'f1_score': f1_score(y_test, y_pred),
            'auc_roc': roc_auc_score(y_test, y_proba),
            'average_precision': average_precision_score(y_test, y_proba),
        }

        # Store for plotting
        self.y_test = y_test
        self.y_pred = y_pred
        self.y_proba = y_proba

        return self.results

    def _specificity(self, y_true, y_pred):
        """Calculate specificity (true negative rate)."""
        tn, fp, fn, tp = confusion_matrix(y_true, y_pred).ravel()
        return tn / (tn + fp)

    def print_report(self):
        """Print detailed evaluation report."""
        print("\n" + "="*60)
        print("MODEL EVALUATION REPORT")
        print("="*60)

        print("\n📊 Performance Metrics:")
        print(f"   Accuracy:          {self.results['accuracy']:.4f} ({self.results['accuracy']*100:.2f}%)")
        print(f"   Precision:         {self.results['precision']:.4f}")
        print(f"   Recall (Sens.):    {self.results['recall']:.4f}")
        print(f"   Specificity:       {self.results['specificity']:.4f}")
        print(f"   F1-Score:          {self.results['f1_score']:.4f}")
        print(f"   AUC-ROC:           {self.results['auc_roc']:.4f}")
        print(f"   Average Precision: {self.results['average_precision']:.4f}")

        print("\n📋 Classification Report:")
        print(classification_report(self.y_test, self.y_pred, target_names=self.class_names))

        # Medical interpretation
        print("\n🏥 Medical Interpretation:")
        print(f"   - Sensitivity (Recall): {self.results['recall']*100:.1f}%")
        print(f"     → {self.results['recall']*100:.1f}% of stones correctly detected")
        print(f"   - Specificity: {self.results['specificity']*100:.1f}%")
        print(f"     → {self.results['specificity']*100:.1f}% of normal cases correctly identified")

        if self.results['recall'] < 0.95:
            print("\n   ⚠️  WARNING: Recall is below 95%. In medical applications,")
            print("      missing kidney stones (false negatives) can be dangerous.")

    def plot_confusion_matrix(self, save_path=None, figsize=(8, 6)):
        """Plot confusion matrix with counts and percentages."""
        cm = confusion_matrix(self.y_test, self.y_pred)
        cm_normalized = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis]

        fig, ax = plt.subplots(figsize=figsize)

        # Create annotations with counts and percentages
        annotations = np.array([[f'{count}\n({pct:.1%})'
                                for count, pct in zip(row_count, row_pct)]
                               for row_count, row_pct in zip(cm, cm_normalized)])

        sns.heatmap(cm, annot=annotations, fmt='', cmap='Blues', ax=ax,
                   xticklabels=self.class_names, yticklabels=self.class_names)

        ax.set_xlabel('Predicted Label', fontsize=12)
        ax.set_ylabel('True Label', fontsize=12)
        ax.set_title('Confusion Matrix', fontsize=14)

        plt.tight_layout()

        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
            print(f"Confusion matrix saved to: {save_path}")

        plt.show()

    def plot_roc_curve(self, save_path=None, figsize=(8, 6)):
        """Plot ROC curve."""
        fpr, tpr, thresholds = roc_curve(self.y_test, self.y_proba)

        fig, ax = plt.subplots(figsize=figsize)

        ax.plot(fpr, tpr, 'b-', linewidth=2,
               label=f'ROC Curve (AUC = {self.results["auc_roc"]:.4f})')
        ax.plot([0, 1], [0, 1], 'r--', linewidth=1, label='Random Classifier')

        # Highlight operating point
        optimal_idx = np.argmax(tpr - fpr)
        optimal_threshold = thresholds[optimal_idx]
        ax.scatter(fpr[optimal_idx], tpr[optimal_idx], c='green', s=100,
                  label=f'Optimal Threshold ({optimal_threshold:.3f})', zorder=5)

        ax.set_xlabel('False Positive Rate (1 - Specificity)', fontsize=12)
        ax.set_ylabel('True Positive Rate (Sensitivity)', fontsize=12)
        ax.set_title('Receiver Operating Characteristic (ROC) Curve', fontsize=14)
        ax.legend(loc='lower right')
        ax.grid(True, alpha=0.3)

        plt.tight_layout()

        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
            print(f"ROC curve saved to: {save_path}")

        plt.show()

        return optimal_threshold

    def plot_precision_recall_curve(self, save_path=None, figsize=(8, 6)):
        """Plot Precision-Recall curve."""
        precision, recall, thresholds = precision_recall_curve(self.y_test, self.y_proba)

        fig, ax = plt.subplots(figsize=figsize)

        ax.plot(recall, precision, 'b-', linewidth=2,
               label=f'PR Curve (AP = {self.results["average_precision"]:.4f})')

        ax.set_xlabel('Recall (Sensitivity)', fontsize=12)
        ax.set_ylabel('Precision', fontsize=12)
        ax.set_title('Precision-Recall Curve', fontsize=14)
        ax.legend(loc='lower left')
        ax.grid(True, alpha=0.3)

        plt.tight_layout()

        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
            print(f"PR curve saved to: {save_path}")

        plt.show()

    def plot_threshold_analysis(self, save_path=None, figsize=(10, 6)):
        """
        Analyze metrics across different thresholds.
        Important for choosing optimal threshold in medical applications.
        """
        thresholds = np.linspace(0, 1, 100)

        precisions = []
        recalls = []
        specificities = []
        f1s = []

        for thresh in thresholds:
            y_pred_thresh = (self.y_proba >= thresh).astype(int)

            # Handle edge cases
            if np.sum(y_pred_thresh) == 0 or np.sum(y_pred_thresh) == len(y_pred_thresh):
                precisions.append(0)
                recalls.append(0)
                specificities.append(0)
                f1s.append(0)
                continue

            precisions.append(precision_score(self.y_test, y_pred_thresh, zero_division=0))
            recalls.append(recall_score(self.y_test, y_pred_thresh, zero_division=0))

            tn, fp, fn, tp = confusion_matrix(self.y_test, y_pred_thresh).ravel()
            specificities.append(tn / (tn + fp) if (tn + fp) > 0 else 0)

            f1s.append(f1_score(self.y_test, y_pred_thresh, zero_division=0))

        fig, ax = plt.subplots(figsize=figsize)

        ax.plot(thresholds, precisions, 'b-', label='Precision', linewidth=2)
        ax.plot(thresholds, recalls, 'g-', label='Recall (Sensitivity)', linewidth=2)
        ax.plot(thresholds, specificities, 'r-', label='Specificity', linewidth=2)
        ax.plot(thresholds, f1s, 'purple', label='F1-Score', linewidth=2, linestyle='--')

        # Mark current threshold (0.5)
        ax.axvline(x=0.5, color='gray', linestyle='--', alpha=0.5, label='Default (0.5)')

        ax.set_xlabel('Classification Threshold', fontsize=12)
        ax.set_ylabel('Score', fontsize=12)
        ax.set_title('Metrics vs Classification Threshold', fontsize=14)
        ax.legend(loc='center right')
        ax.grid(True, alpha=0.3)

        plt.tight_layout()

        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
            print(f"Threshold analysis saved to: {save_path}")

        plt.show()

    def generate_full_report(self, output_dir='../models/evaluation'):
        """
        Generate complete evaluation report with all plots.

        Args:
            output_dir: Directory to save all outputs
        """
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        print("\n📊 Generating Full Evaluation Report...")

        # Print metrics
        self.print_report()

        # Generate plots
        self.plot_confusion_matrix(output_path / 'confusion_matrix.png')
        optimal_threshold = self.plot_roc_curve(output_path / 'roc_curve.png')
        self.plot_precision_recall_curve(output_path / 'pr_curve.png')
        self.plot_threshold_analysis(output_path / 'threshold_analysis.png')

        # Save metrics to JSON
        import json
        metrics_path = output_path / 'metrics.json'
        with open(metrics_path, 'w') as f:
            json.dump(self.results, f, indent=2)

        print(f"\n✅ Full report saved to: {output_path}")
        print(f"   - Metrics: metrics.json")
        print(f"   - Confusion Matrix: confusion_matrix.png")
        print(f"   - ROC Curve: roc_curve.png")
        print(f"   - PR Curve: pr_curve.png")
        print(f"   - Threshold Analysis: threshold_analysis.png")
        print(f"\n💡 Optimal threshold: {optimal_threshold:.3f}")

        return self.results


def compare_models(models_dict, X_test, y_test, save_path=None):
    """
    Compare multiple models on the same test set.

    Args:
        models_dict: Dictionary of {model_name: model}
        X_test, y_test: Test data
        save_path: Path to save comparison plot

    Returns:
        Comparison dataframe
    """
    import pandas as pd

    results = []

    for name, model in models_dict.items():
        evaluator = ModelEvaluator(model)
        metrics = evaluator.evaluate(X_test, y_test)
        metrics['model'] = name
        results.append(metrics)

    df = pd.DataFrame(results)
    df = df.set_index('model')

    print("\n📊 Model Comparison:")
    print(df.round(4).to_string())

    # Plot comparison
    fig, ax = plt.subplots(figsize=(12, 6))

    metrics_to_plot = ['accuracy', 'precision', 'recall', 'f1_score', 'auc_roc']
    x = np.arange(len(metrics_to_plot))
    width = 0.8 / len(models_dict)

    for i, (name, _) in enumerate(models_dict.items()):
        values = df.loc[name, metrics_to_plot].values
        ax.bar(x + i * width, values, width, label=name)

    ax.set_ylabel('Score')
    ax.set_title('Model Comparison')
    ax.set_xticks(x + width * (len(models_dict) - 1) / 2)
    ax.set_xticklabels(metrics_to_plot)
    ax.legend()
    ax.set_ylim(0, 1)
    ax.grid(True, alpha=0.3, axis='y')

    plt.tight_layout()

    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches='tight')
        print(f"Comparison plot saved to: {save_path}")

    plt.show()

    return df


if __name__ == "__main__":
    print("RayScan Model Evaluator")
    print("="*50)
    print("\nUsage:")
    print("  evaluator = ModelEvaluator(trained_model)")
    print("  results = evaluator.evaluate(X_test, y_test)")
    print("  evaluator.generate_full_report()")

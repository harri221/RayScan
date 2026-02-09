"""
Train XResNet50 model on ultrasound kidney stone dataset
Based on muhammedtalo's 96.82% accuracy model
"""
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'  # Suppress TF warnings

print("=" * 60)
print("TRAINING XRESNET50 MODEL (96.82% accuracy architecture)")
print("=" * 60)

try:
    from fastai.vision.all import *
    print("\n[OK] fastai library loaded")
except ImportError:
    print("\n[ERROR] fastai not installed!")
    print("Installing fastai...")
    import subprocess
    subprocess.run(["pip", "install", "fastai", "-q"])
    from fastai.vision.all import *
    print("[OK] fastai installed and loaded")

# Configuration
DATASET_DIR = Path(r'c:\Users\Admin\Downloads\flutter_application_1\ds')

print(f"\n[STEP 1] Loading dataset from: {DATASET_DIR}")

# Get all images
all_images = get_image_files(DATASET_DIR)
print(f"[OK] Found {len(all_images)} total images")

# Check class distribution
from collections import Counter
labels = [img.parent.name for img in all_images]
label_counts = Counter(labels)
print(f"\nClass distribution:")
for label, count in label_counts.items():
    print(f"  {label}: {count} images")

# Data augmentation (same as original model)
print(f"\n[STEP 2] Creating data loaders with augmentation...")
augs = [
    RandomResizedCropGPU(size=224, min_scale=0.75),
    Rotate(),
    Zoom()
]

dblock = DataBlock(
    blocks=(ImageBlock(cls=PILImage), CategoryBlock),
    splitter=RandomSplitter(valid_pct=0.2, seed=42),
    get_y=parent_label,
    item_tfms=Resize(512, method="squish"),
    batch_tfms=augs,
)

dls = dblock.dataloaders(DATASET_DIR, bs=32)

print(f"[OK] Data loaders created")
print(f"  Classes: {dls.vocab}")
print(f"  Training samples: {len(dls.train_ds)}")
print(f"  Validation samples: {len(dls.valid_ds)}")

# Show sample batch
print(f"\n[STEP 3] Sample batch preview...")
try:
    dls.show_batch(max_n=4)
except:
    print("  (Unable to display batch - that's okay)")

# Build model (XResNet50 architecture)
print(f"\n[STEP 4] Building XResNet50 model...")
model = nn.Sequential(
    create_body(xresnet50, pretrained=False),  # XResNet50 backbone
    create_head(nf=2048, n_out=2)  # 2 classes: stone, normal
)

learn = Learner(
    dls,
    model,
    loss_func=CrossEntropyLossFlat(),
    metrics=accuracy
)

print(f"[OK] Model created")
print(f"  Architecture: XResNet50")
print(f"  Output classes: 2 (kidney_stone, normal)")

# Train model
print("\n" + "=" * 60)
print("TRAINING (40 epochs with One Cycle Policy)")
print("=" * 60)

learn.fit_one_cycle(40, lr_max=1e-2)

print("\n" + "=" * 60)
print("TRAINING COMPLETED!")
print("=" * 60)

# Save model
model_path = 'xresnet50_kidney_stone.pth'
learn.save(model_path)
print(f"\n[OK] Model saved: {model_path}")

# Evaluate
print(f"\n[STEP 5] Evaluating model...")
results = learn.validate()
loss, accuracy = results[0], results[1]

print(f"\nValidation Results:")
print(f"  Loss: {loss:.4f}")
print(f"  Accuracy: {accuracy * 100:.2f}%")

# Classification report
print(f"\n[STEP 6] Generating classification report...")
interp = ClassificationInterpretation.from_learner(learn)

# Get predictions
preds, targets = learn.get_preds()
pred_classes = preds.argmax(dim=1)

# Calculate metrics
from sklearn.metrics import classification_report, confusion_matrix
import numpy as np

print("\nClassification Report:")
print(classification_report(
    targets.numpy(),
    pred_classes.numpy(),
    target_names=dls.vocab
))

print("\nConfusion Matrix:")
cm = confusion_matrix(targets.numpy(), pred_classes.numpy())
print(f"                Predicted")
print(f"              Stone  Normal")
print(f"Actual Stone    {cm[0][0]:4d}   {cm[0][1]:4d}")
print(f"       Normal   {cm[1][0]:4d}   {cm[1][1]:4d}")

# Check if model is working
stone_recall = cm[0][0] / (cm[0][0] + cm[0][1])
normal_recall = cm[1][1] / (cm[1][0] + cm[1][1])

print("\n" + "=" * 60)
print("DIAGNOSIS")
print("=" * 60)

if accuracy < 0.6:
    print("\n[CRITICAL] Model accuracy is very low!")
    print("Possible reasons:")
    print("  1. Ultrasound images are too different from CT training data")
    print("  2. Dataset has grayscale/RGB mismatch issue")
    print("  3. Model needs different architecture for ultrasound")
elif stone_recall < 0.5:
    print("\n[WARNING] Model can't detect stones well!")
    print(f"  Stone recall: {stone_recall*100:.1f}%")
    print("  The model is biased towards 'normal' predictions")
else:
    print(f"\n[SUCCESS] Model is working!")
    print(f"  Overall accuracy: {accuracy * 100:.2f}%")
    print(f"  Stone detection rate: {stone_recall * 100:.2f}%")
    print(f"  Normal detection rate: {normal_recall * 100:.2f}%")

# Export for inference
print(f"\n[STEP 7] Exporting model for deployment...")
learn.export('xresnet50_export.pkl')
print(f"[OK] Exported model: xresnet50_export.pkl")

print("\n" + "=" * 60)
print("NEXT STEPS")
print("=" * 60)

if accuracy > 0.8:
    print("\n Model performed well! Next:")
    print("  1. Convert to ONNX format")
    print("  2. Convert ONNX to TFLite for Flutter")
    print("  3. Integrate into your app")
else:
    print("\nModel didn't perform well on ultrasound images.")
    print("Recommendation:")
    print("  1. Fix dataset format issue (python fix_dataset.py)")
    print("  2. Train custom CNN on your specific ultrasound data")
    print("  3. XResNet50 was trained on CT, not ultrasound!")

print("\n" + "=" * 60)

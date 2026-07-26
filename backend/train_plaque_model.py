"""
PyTorch Training & ONNX Export Script for PlaqueCheck Deep Learning Engine
Target Dataset: Mendeley 10,000+ Pre-staining Intraoral Images (Teeth 5-5)
Labels: 0 (No Plaque), 1 (Mild Plaque), 2 (Moderate Plaque), 3 (High Plaque), 4 (Severe Plaque)
"""

import argparse
from pathlib import Path
import time

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, Dataset
from torchvision import models, transforms
from PIL import Image, ImageFile

ImageFile.LOAD_TRUNCATED_IMAGES = True

BACKEND_DIR = Path(__file__).resolve().parent
DATASET_DIR = BACKEND_DIR / "dataset"
MODELS_DIR = BACKEND_DIR / "models"
ONNX_EXPORT_PATH = MODELS_DIR / "plaque_model.onnx"
PT_EXPORT_PATH = MODELS_DIR / "plaque_model.pt"


def _compute_label_from_annotation(lbl_path: Path) -> int:
    if not lbl_path.exists():
        return 0
    try:
        lines = lbl_path.read_text().strip().splitlines()
    except Exception:
        return 0

    if not lines:
        return 0

    plaque_count = 0
    total_count = 0
    for line in lines:
        parts = line.strip().split()
        if parts:
            try:
                is_plaque = int(parts[0])
                total_count += 1
                if is_plaque == 1:
                    plaque_count += 1
            except ValueError:
                pass

    if total_count == 0 or plaque_count == 0:
        return 0

    ratio = plaque_count / total_count
    if ratio < 0.20:
        return 1
    if ratio < 0.45:
        return 2
    if ratio < 0.70:
        return 3
    return 4


class IntraoralPlaqueDataset(Dataset):
    def __init__(self, data_dir: Path, transform=None):
        self.data_dir = data_dir
        self.transform = transform
        self.samples = []

        # 1. Search for Mendeley data structure (data/images and data/labels)
        found_images = list(data_dir.glob("**/data/images"))
        found_labels = list(data_dir.glob("**/data/labels"))

        if found_images and found_labels:
            images_dir = found_images[0]
            labels_dir = found_labels[0]
            print(f"--> Found Mendeley dataset structure: {images_dir}")

            for split in ["train", "valid", "test"]:
                split_img_dir = images_dir / split
                split_lbl_dir = labels_dir / split
                if not split_img_dir.exists():
                    continue

                for patient_dir in split_img_dir.glob("*"):
                    if not patient_dir.is_dir():
                        continue
                    lbl_patient_dir = split_lbl_dir / patient_dir.name
                    for ext in ["*.jpg", "*.jpeg", "*.png", "*.JPG", "*.PNG"]:
                        for img_path in patient_dir.glob(ext):
                            lbl_path = lbl_patient_dir / f"{img_path.stem}.txt"
                            label = _compute_label_from_annotation(lbl_path)
                            self.samples.append((img_path, label))

        # 2. Fallback search for directory-per-class (0, 1, 2, 3, 4)
        if len(self.samples) == 0:
            for class_dir in sorted(data_dir.glob("*")):
                if class_dir.is_dir():
                    label_str = class_dir.name.split("-")[0]
                    if label_str.isdigit():
                        label = min(int(label_str), 4)
                        for ext in ["*.jpg", "*.jpeg", "*.png", "*.JPG", "*.PNG"]:
                            for img_path in class_dir.glob(ext):
                                self.samples.append((img_path, label))

        print(f"--> Total intraoral dataset samples loaded: {len(self.samples)}")

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        path, label = self.samples[idx]
        try:
            image = Image.open(path).convert("RGB")
        except Exception:
            # Fallback for any corrupted or truncated image file
            image = Image.new("RGB", (224, 224), (128, 128, 128))

        if self.transform:
            image = self.transform(image)
        return image, label


def get_data_transforms():
    train_transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.RandomHorizontalFlip(),
        transforms.RandomRotation(10),
        transforms.ColorJitter(brightness=0.15, contrast=0.15),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])

    val_transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])

    return train_transform, val_transform


def build_model(num_classes: int = 5):
    # MobileNetV3 Large backbone for ultra-fast ONNX cloud inference
    model = models.mobilenet_v3_large(weights=models.MobileNet_V3_Large_Weights.DEFAULT)
    in_features = model.classifier[3].in_features
    model.classifier[3] = nn.Linear(in_features, num_classes)
    return model


def train_and_export(
    data_dir: Path = DATASET_DIR,
    epochs: int = 15,
    batch_size: int = 32,
    lr: float = 1e-4,
):
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"--> Starting PlaqueCheck AI Training on Device: {device}", flush=True)

    train_tf, val_tf = get_data_transforms()
    dataset = IntraoralPlaqueDataset(data_dir, transform=train_tf)

    if len(dataset) == 0:
        print(f"No intraoral dataset found in {data_dir}.")
        return

    train_size = int(0.85 * len(dataset))
    val_size = len(dataset) - train_size
    train_dataset, val_dataset = torch.utils.data.random_split(dataset, [train_size, val_size])

    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True, num_workers=0)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False, num_workers=0)

    model = build_model(num_classes=5).to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.AdamW(model.parameters(), lr=lr, weight_decay=1e-4)

    best_acc = 0.0

    for epoch in range(1, epochs + 1):
        start_t = time.time()
        model.train()
        running_loss = 0.0

        for images, labels in train_loader:
            images, labels = images.to(device), labels.to(device)
            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            running_loss += loss.item() * images.size(0)

        epoch_loss = running_loss / len(train_dataset)

        # Validation
        model.eval()
        correct = 0
        total = 0
        with torch.no_grad():
            for images, labels in val_loader:
                images, labels = images.to(device), labels.to(device)
                outputs = model(images)
                _, preds = torch.max(outputs, 1)
                total += labels.size(0)
                correct += (preds == labels).sum().item()

        val_acc = correct / total if total > 0 else 0
        elapsed = time.time() - start_t
        print(f"Epoch {epoch}/{epochs} [{elapsed:.1f}s] - Train Loss: {epoch_loss:.4f} | Val Acc: {val_acc*100:.2f}%", flush=True)

        if val_acc >= best_acc:
            best_acc = val_acc
            torch.save(model.state_dict(), PT_EXPORT_PATH)
            export_onnx(model, device)

    print(f"--> Training Complete! Best Validation Accuracy: {best_acc*100:.2f}%")
    print(f"--> ONNX Model Exported to: {ONNX_EXPORT_PATH}")


def export_onnx(model: nn.Module, device: torch.device):
    model.eval()
    dummy_input = torch.randn(1, 3, 224, 224, device=device)
    torch.onnx.export(
        model,
        dummy_input,
        str(ONNX_EXPORT_PATH),
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={"input": {0: "batch_size"}, "output": {0: "batch_size"}},
        opset_version=14,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train PlaqueCheck Deep Learning Model")
    parser.add_argument("--data_dir", type=str, default=str(DATASET_DIR))
    parser.add_argument("--epochs", type=int, default=15)
    parser.add_argument("--batch_size", type=int, default=32)
    parser.add_argument("--lr", type=float, default=1e-4)
    args = parser.parse_args()

    train_and_export(
        data_dir=Path(args.data_dir),
        epochs=args.epochs,
        batch_size=args.batch_size,
        lr=args.lr,
    )

"""
Test the Flask API Server
"""
import requests
from pathlib import Path
import random

print("=" * 60)
print("TESTING KIDNEY STONE DETECTION API")
print("=" * 60)

API_URL = "http://127.0.0.1:5000"

# Test 1: Health Check
print("\n[TEST 1] Health Check...")
try:
    response = requests.get(f"{API_URL}/")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print("[OK] Server is online!")
except Exception as e:
    print(f"[ERROR] {e}")
    exit(1)

# Test 2: Predict on stone image
print("\n[TEST 2] Testing with STONE image...")
stone_dir = Path(r'c:\Users\Admin\Downloads\flutter_application_1\ds\stone')
stone_sample = random.choice(list(stone_dir.glob("*.jpg")))

print(f"Image: {stone_sample.name}")

with open(stone_sample, 'rb') as f:
    files = {'image': f}
    response = requests.post(f"{API_URL}/predict", files=files)

print(f"Status: {response.status_code}")
result = response.json()

if result.get('success'):
    print(f"[OK] Prediction: {result['prediction']}")
    print(f"     Confidence: {result['confidence']:.1f}%")
    print(f"     Diagnosis: {result['result']['diagnosis']}")

    if result['prediction'] == 'stone':
        print("[SUCCESS] Correctly identified kidney stone!")
    else:
        print("[FAIL] Should have detected kidney stone!")
else:
    print(f"[ERROR] {result.get('error')}")

# Test 3: Predict on normal image
print("\n[TEST 3] Testing with NORMAL image...")
normal_dir = Path(r'c:\Users\Admin\Downloads\flutter_application_1\ds\normal')
normal_sample = random.choice(list(normal_dir.glob("*.jpg")))

print(f"Image: {normal_sample.name}")

with open(normal_sample, 'rb') as f:
    files = {'image': f}
    response = requests.post(f"{API_URL}/predict", files=files)

print(f"Status: {response.status_code}")
result = response.json()

if result.get('success'):
    print(f"[OK] Prediction: {result['prediction']}")
    print(f"     Confidence: {result['confidence']:.1f}%")
    print(f"     Diagnosis: {result['result']['diagnosis']}")

    if result['prediction'] == 'normal':
        print("[SUCCESS] Correctly identified normal kidney!")
    else:
        print("[FAIL] Should have detected normal kidney!")
else:
    print(f"[ERROR] {result.get('error')}")

print("\n" + "=" * 60)
print("API TESTING COMPLETE!")
print("=" * 60)
print("\nAPI is ready for Flutter integration!")
print(f"\nAPI URL: {API_URL}")
print("Endpoints:")
print(f"  GET  {API_URL}/")
print(f"  POST {API_URL}/predict")

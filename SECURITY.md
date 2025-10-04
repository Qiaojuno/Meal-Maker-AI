# 🔒 Security Notice - Hackathon MVP

## ⚠️ Current Status: DEMO ONLY - NOT PRODUCTION READY

This is a **24-hour hackathon MVP**. The current implementation has a **known security vulnerability** that is acceptable for demo purposes but **MUST be fixed before any production deployment**.

---

## 🚨 Known Security Issue

### **Problem: Hardcoded API Key in Frontend**

**Location:** `Meal Maker AI/Utils/Config.swift:37`

```swift
static var geminiAPIKey: String {
    return "AIzaSyD3K3llXHluUU0UEeHuRoDsBvVbNuCJKrM"  // ⚠️ INSECURE
}
```

**Risk Level:** 🔴 **HIGH**

**Why This Is Bad:**
- ❌ Anyone can decompile the iOS app and extract the API key
- ❌ Stolen key could be used to rack up charges on your Google Cloud account
- ❌ No rate limiting or abuse prevention
- ❌ Violates Google's API key security best practices
- ❌ App Store will reject this during review

**Why We Did This Anyway:**
- ✅ Hackathon time constraint (24 hours)
- ✅ MVP demo-only deployment
- ✅ Not publicly distributed
- ✅ Clear migration path documented

---

## ✅ Production-Ready Solution (POST-HACKATHON)

### **Step 1: Create Backend Proxy Server**

**Option A: Node.js/Express (Recommended)**

```javascript
// server.js
const express = require('express');
const app = express();

app.post('/api/identify-ingredients', async (req, res) => {
    const { image } = req.body;

    // Call Gemini API with server-side API key (from env variable)
    const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${process.env.GEMINI_API_KEY}`,
        {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }, { inline_data: { mime_type: 'image/jpeg', data: image }}]}]
            })
        }
    );

    return res.json(await response.json());
});

app.listen(3000);
```

**Option B: Python/Flask**

```python
# app.py
from flask import Flask, request, jsonify
import os
import requests

app = Flask(__name__)
GEMINI_API_KEY = os.environ['GEMINI_API_KEY']

@app.route('/api/identify-ingredients', methods=['POST'])
def identify_ingredients():
    image = request.json['image']

    response = requests.post(
        f'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={GEMINI_API_KEY}',
        json={'contents': [{'parts': [{'text': prompt}, {'inline_data': {'mime_type': 'image/jpeg', 'data': image}}]}]}
    )

    return jsonify(response.json())
```

**Option C: Firebase Cloud Functions**

```javascript
// functions/index.js
const functions = require('firebase-functions');
const fetch = require('node-fetch');

exports.identifyIngredients = functions.https.onCall(async (data, context) => {
    const apiKey = functions.config().gemini.apikey;
    const { image } = data;

    const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`,
        {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }, { inline_data: { mime_type: 'image/jpeg', data: image }}]}]
            })
        }
    );

    return response.json();
});
```

---

### **Step 2: Deploy Backend**

**Free Options:**
- **Vercel** (Node.js): https://vercel.com (Recommended for quick deploy)
- **Railway** (Any language): https://railway.app
- **Render** (Any language): https://render.com
- **Firebase** (Cloud Functions): https://firebase.google.com
- **Heroku** (Any language): https://heroku.com (Free tier available)

---

### **Step 3: Update iOS App**

**Change in `GeminiService.swift`:**

```swift
// OLD (Hackathon MVP):
let endpoint = "\(baseURL)/\(visionModel):generateContent?key=\(apiKey)"

// NEW (Production):
let endpoint = "https://your-backend.com/api/identify-ingredients"
// Remove API key from iOS app entirely
```

**Full function update:**

```swift
private func makeVisionAPICall<T: Decodable>(prompt: String, image: String) async throws -> T {
    // Production endpoint (your backend)
    let endpoint = "https://your-backend.com/api/identify-ingredients"

    guard let url = URL(string: endpoint) else {
        throw GeminiError.invalidURL
    }

    // Send image to YOUR backend (no API key needed)
    let requestBody: [String: Any] = [
        "prompt": prompt,
        "image": image
    ]

    // Your backend handles the Gemini API call securely
    return try await performRequest(url: url, body: requestBody)
}
```

---

### **Step 4: Security Checklist**

Before production deployment:

- [ ] Remove hardcoded API key from `Config.swift`
- [ ] Deploy backend proxy server
- [ ] Move API key to backend environment variables
- [ ] Update `GeminiService.swift` to call backend endpoints
- [ ] Implement rate limiting on backend (e.g., 10 requests/minute per user)
- [ ] Add authentication (Firebase Auth, JWT, etc.)
- [ ] Enable HTTPS only
- [ ] Set up monitoring for API usage
- [ ] Add error handling for backend failures
- [ ] Test with invalid/malicious requests
- [ ] Update `.gitignore` to exclude any new secrets

---

## 📊 Estimated Migration Time

- **Backend Setup:** 30-45 minutes
- **iOS App Updates:** 15-20 minutes
- **Testing:** 15-20 minutes
- **Total:** ~1-1.5 hours

---

## 🎯 Acceptable Use (Current State)

✅ **Allowed:**
- Hackathon demos
- Local testing
- Proof-of-concept presentations
- Private GitHub repos (with warnings)

❌ **NOT Allowed:**
- App Store submission
- Public distribution
- Production deployment
- Sharing publicly with API key intact

---

## 📞 Questions?

If you're unsure about any security aspects, consult:
- Google Cloud Security Best Practices: https://cloud.google.com/security/best-practices
- OWASP Mobile Security: https://owasp.org/www-project-mobile-security/
- iOS Security Guide: https://support.apple.com/guide/security/welcome/web

---

**Last Updated:** October 4, 2025
**Status:** 🟡 Hackathon MVP - Security migration required before production

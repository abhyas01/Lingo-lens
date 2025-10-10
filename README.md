# Lingo lens (Winner - Apple Swift Student Challenge 2025)

_See. Translate. Learn._

- Lingo lens is an **augmented reality (AR) language learning app** that transforms your surroundings into an interactive vocabulary builder.  

- Using your device’s camera, Lingo lens identifies everyday objects, allows you to **anchor labels in 3D space**, and when you tap a label it reveals the translation and plays the correct pronunciation.  

## Achievement  

This app, in its **pre-mature state** at commit `e163259a2cf234c037cc77b1eff6b222212c42e3`, was submitted for the **Apple Swift Student Challenge 2025**, and it **won the Swift Student Challenge**. 🎉  

## Demo  

Watch the demo video showcasing Lingo Lens in action.  

_Note: Uploaded at 2× speed, pronunciation may sound faster._

https://github.com/user-attachments/assets/d19d27b6-e487-46b6-bb54-15adb89e8789

## How It Works  

1. Point the camera at an object.  
2. Adjust the detection box and anchor a label in 3D space.  
3. **Tap the anchored label** to reveal its translation and hear the pronunciation.
4. Long press a label to delete it.
5. Save the word to your personal collection for review later.

## Key Technologies  

| Framework / Component | Purpose |
|-----------------------|----------|
| **ARKit** | Spatial tracking and anchoring labels in the real world |
| **Vision + CoreML** | Real-time object recognition and inference |
| **Apple Translation Framework** | Accurate translations for detected objects |
| **AVFoundation** | Speech synthesis for pronunciation playback |
| **CoreData** | Local persistence for saved words and settings |

_Note: All processing happens **on-device** for privacy and offline usability._

## Future Development  

Planned improvements:  
- Enhanced object recognition accuracy.  
- Expanded language and voice support.  
- iCloud sync for saved vocabulary.  
- Gamified progress tracking and achievements.

_Note: Lingo Lens works best on Pro iPhones/iPads with a LiDAR sensor. Placing anchors on objects may take a few retries on other devices due to hardware limitations, and I'm actively working to improve this experience._

## Author  

**Developed by:** Abhyas Mall  
**Project:** Lingo lens  
**Contact:** mallabhyas@gmail.com / abhyas@uchicago.edu

# Lingo lens (🏆 Winner - Apple Swift Student Challenge 2025)

<div align="center">
    <img
        width="150"
        alt="Lingo lens"
        src="https://github.com/user-attachments/assets/35b8a54e-a877-4c25-a2ef-936aee0f7d98"
    />
    <p>See. Translate. Learn.</p>
</div>

- Lingo lens is an **augmented reality (AR) language learning app** that transforms your surroundings into an interactive vocabulary builder.  

- Using your device’s camera, Lingo lens identifies everyday objects, allows you to **anchor labels in 3D space**, and when you tap a label it reveals the translation and plays the correct pronunciation.  

## Achievement  

This app, in its **pre-mature state** at commit `e163259a2cf234c037cc77b1eff6b222212c42e3`, was submitted for the **Apple Swift Student Challenge 2025**, and it **won the Swift Student Challenge**. 🎉  

## Demo  

Watch the demo video showcasing Lingo Lens in action.  

_Note: Uploaded at 2× speed, pronunciation may sound faster._

https://github.com/user-attachments/assets/944a0b48-c240-4d12-9631-9ce407146e83

## How It Works  

1. Select the language you want to learn.
2. Point the camera at an object.  
3. Adjust the detection box and anchor a label in 3D space.  
4. **Tap the anchored label** to reveal its translation and hear the pronunciation.
5. Long press a label to delete it.
6. Save the word to your personal collection.

## Key Technologies  

| Framework / Component | Purpose |
|-----------------------|----------|
| **ARKit** | Spatial tracking and anchoring labels in the real world |
| **Vision + CoreML** | FastViT image classifier for real-time object recognition |
| **Apple Translation Framework** | Accurate translations for detected objects |
| **AVFoundation** | Speech synthesis for pronunciation playback |
| **CoreData** | Local persistence for saved words and settings |

_Note: All processing happens **on-device** for privacy and offline usability._

## User Interface

| **Section** | **Screenshot** | **Description** |
|---------|----------------|----------------|
| **Translate Tab** | <img width="400" alt="ar-config-stage-ui-update-to-user" src="https://github.com/user-attachments/assets/aa047e6b-6808-41ee-a3a4-a719d417298b" /> | AR initializes and communicates its status to the user. |
|  | <img width="400" alt="detection-mode" src="https://github.com/user-attachments/assets/fc59bccf-a8c1-4c3d-83dd-d3c617cdce15" /> | Shows the app in Detection Mode. |
|  | <img width="400" alt="anchor-labels" src="https://github.com/user-attachments/assets/e17b2856-0281-4bc4-8340-f4fffcd132cd" /> | Shows the anchored labels visible in 3D space. |
|  | <img width="400" alt="translation-label-unsaved" src="https://github.com/user-attachments/assets/f9c957ec-6da7-4ae2-8f6e-8f86819e29ce" /> | Translation pop-up for "coffee mug" and options to Listen or Save (orange, unsaved). |
|  | <img width="400" alt="translation-label-saved" src="https://github.com/user-attachments/assets/1c1a8030-c278-412b-b5e9-72b4bdcf0008" /> | Translation pop-up for "laptop"; shows it has been Saved (green checkmark) and allows Listen. |
|  | <img width="400" alt="lang-not-installed-check" src="https://github.com/user-attachments/assets/ca45c270-f61c-435b-a38c-5117a20fba52" /> | Triggered when detection mode starts but the selected language isn’t installed (edge case). |
|  | <img width="400" alt="camera-permission-check" src="https://github.com/user-attachments/assets/e228461a-a8d0-4f81-b4a9-09109c8bb9f5" /> | Shown on the Translate tab when camera access is not granted, prompting the user to enable permissions. |
| **Saved Words Tab** | <img width="400" alt="saved-words" src="https://github.com/user-attachments/assets/1383ffe9-3c4f-49cb-b43e-e2f38b478d89" /> | Vocabulary list saved by the user. |
|  | <img width="400" alt="saved-words-filtering" src="https://github.com/user-attachments/assets/191d93f5-7e2b-4edf-9371-166da2a94ee1" /> | Vocabulary list filtering by language. |
|  | <img width="400" alt="saved-words-sorting" src="https://github.com/user-attachments/assets/402e0c56-a990-491c-b9de-0230d5b15e78" /> | Vocabulary list sorted by date added. |
|  | <img width="400" alt="saved-word-detail-view" src="https://github.com/user-attachments/assets/a92d5744-f4dc-4a4c-9eae-b0b1fe4d0b2e" /> | Saved Word Detail View
| **Settings Tab** | <img width="400" alt="settings-tab" src="https://github.com/user-attachments/assets/fce4aced-aaa5-404f-a4e1-c03b38c2fc3a" /> | Settings tab for selecting language and color scheme. 
|  | <img width="400" alt="lang-selection" src="https://github.com/user-attachments/assets/27ae9750-baeb-44d9-be9c-0c18f309d5f9" /> | Language selection sheet. |
|  | <img width="400" alt="color-scheme" src="https://github.com/user-attachments/assets/24b98c9b-ee05-45c5-8904-81148b8037ed" /> | Color Scheme settings. |
| Onboarding Screen | <img width="400" alt="onboarding-1" src="https://github.com/user-attachments/assets/83769ac4-109f-4f41-bc69-2edfcc4abc5e" /> | Shown when the user downloads the app and opens it for the first time (Onboarding 1/4) |
|  | <img width="400" alt="onboarding-2" src="https://github.com/user-attachments/assets/71dfacd1-d226-4d7c-a954-a81a6e6f6de0" /> | Onboarding 2/4 |
|  | <img width="400" alt="onboarding-3" src="https://github.com/user-attachments/assets/9e6c4179-5fb2-4b31-b6d4-7bc1605dcb90" /> | Onboarding 3/4 |
|  | <img width="400" alt="onboarding-4" src="https://github.com/user-attachments/assets/c10993a6-8801-4abe-9898-f1fe406b7816" /> | Onboarding 4/4 |
| Instructions Sheet | <img width="400" alt="ins(1:3)" src="https://github.com/user-attachments/assets/2294a70d-fd69-4a2e-a824-f3b622d54667" /> | Shown when the user opens the Translate tab for the first time after downloading the app, and also appears when the info button is tapped on the Translate tab (Instruction Sheet 1/3) |
|  | <img width="400" alt="ins(2:3)" src="https://github.com/user-attachments/assets/7f496c5b-0ea9-4e91-bcd7-accd695caffc" /> | Instruction Sheet 2/3 |
|  | <img width="400" alt="ins(3:3)" src="https://github.com/user-attachments/assets/755ac239-bd2c-4454-aaa7-21b02339d612" /> | Instruction Sheet 3/3 |

## Future Development  

Planned improvements:  
- Enhanced object recognition accuracy.  
- iCloud sync for saved vocabulary.  
- Gamified progress tracking and achievements.

_Note: Lingo Lens works best on Pro iPhones/iPads with a LiDAR sensor. Placing anchors on objects may take a few retries on other devices due to hardware limitations, and I'm actively working to improve this experience._

## Project Context

Lingo lens was developed as the final project for the course [MPCS 51030 iOS Application Development (Winter 2025)](https://mpcs-courses.cs.uchicago.edu/2024-25/winter/courses/mpcs-51030-1) at the **University of Chicago**.

## Author  

**Developed by:** Abhyas Mall  
**Project:** Lingo lens  
**Contact:** mallabhyas@gmail.com

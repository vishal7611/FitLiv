# FitLiv - AI based Fitness Form Detection and Correction Mobile Application

## What is FitLiv ?

### FitLiv is design and develop an AI based fitness monitoring mobile application that assists physiotherapists in remotely monitoring patient exercises while providing patients with real time corrective feedback

- To implement real time human pose estimation using mobile friendly AI models
  
- To analyze joint angles and range of motion for physiotherapy exercises
  
- To accurately count repetitions using algorithmic state based logic
  
- To provide instant feedback for incorrect posture or incomplete movements
  
- To enable data driven monitoring of patient progress by physiotherapists

## Features 
- Real time pose detection using camera
- Real time on screen monitoring using messages and voice command
- Gives a detail post workout data
- Local Storage of data
- Keeps records of past workouts

## Images of the screens
<p align="center">
  <img src="screenshorts/Login Screen.jpeg" width="320px" >
  <img src="screenshorts/Home screen.jpg" width="320px">
  <img src="screenshorts/stats Screen.jpeg" width="320px">
</p>

<p align="center">
<img src="screenshorts/Analysis screen.jpeg" width="320px">
<img src="screenshorts/Performages log.jpeg" width="320px">
<img src="screenshorts/630c13a50a24422ba23e0492d4789dba.gif" width="320px">
  
</p>

# 🛠 Tech Stack

## Frontend

- Flutter
- Dart

## AI

- Google ML Kit Pose Detection

## Health

- Android Health Connect

## Storage

- SharedPreferences

## Voice

- Flutter TTS

## Camera

- Flutter Camera Package


# Data Flow Architecture

The application processes data through four main stages, from collecting information to storing workout results.

## 1. Data Acquisition (Collecting Data)

### The app collects information from two different sources.

#### Camera Input

[*Location: health_service.dart → fetchLatestMetrics()*](services/health_service.dart)

- Starts the front camera.
- Captures video at approximately 30 frames per second (FPS).
- Each frame is received as a CameraImage object.
- Health Data


#### Connects to Android Health Connect.

- Retrieves the latest:
- Heart Rate (BPM)
- Blood Oxygen (SpO₂)
- Reads data that has been synced from the connected smartwatch (such as an Ambrane watch).

## 2. Data Pre-processing (Preparing the Data)

[*Location: exercise_screen.dart → _inputImageFromCameraImage()*](screens/exercise_screen.dart)
<a href="screens/exercise_screen.dart"/>


### Before analysis, the collected data is converted into a format the app can use.

- Converts the raw camera frame (YUV420) into an InputImage.
- Adds important information such as:
- Image rotation
- Image format
- This ensures the AI model correctly interprets the camera image.

### **Health Data Selection**

[*Location: health_service.dart → fetchLatestMetrics()*](services/health_services.dart)
<a href="services/health_services.dart"/>
services/health_services.dart

Smartwatches often sync multiple records at once.
The app looks back over the last 10 minutes.
It selects the most recent heart rate and SpO₂ values to display the latest health information.

## 3. Processing & Analysis (AI and Exercise Detection)

This stage performs pose detection, angle calculation, and repetition counting.

### Pose Detection

[*Location: exercise_screen.dart → _processCameraImage()*](href="utils/pose_angle_utils.dart)
<a href="utils/pose_angle_utils.dart"/>


Sends the prepared image to Google ML Kit Pose Detector.
The model detects 33 body landmarks representing different joints.

### Joint Angle Calculation

Uses trigonometry (atan2) to calculate joint angles.
*Example:*
Shoulder → Elbow → Wrist
These angles help determine exercise movement.
Exercise Analysis

### Classes:

- BicepCurlAnalyzer
- PushUpAnalyzer

*the analyzers perform the following functions*
- Track body movement using calculated joint angles.
- Detect complete exercise repetitions.
- threshold-based state transitions (Down → Up).
- Verify proper exercise form, such as body or hip alignment.

## 4. Data Storage (Saving Workout Results)

### Once a workout session is complete, the results are saved locally.

[*Location: workout_session.dart → toMap()*](services/workout_storage_services.dart)
<a href="services/workout_storage_services.dart"/>

### The app collects workout information such as:

- Total repetitions
- Heart rate
- Workout duration
- Exercise efficiency

*These values are stored inside a WorkoutSession object and converted into JSON format.*

- Saves the JSON data using SharedPreferences.
- Stores workout history in the device's private storage.
- Allows previous workout sessions to remain available even after the app is closed or restarted.


# Reference
**Any one reading this Please visit the following links that will hselp you to know the various classes that used in this project**

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

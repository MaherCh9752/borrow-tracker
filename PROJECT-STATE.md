# Borrow Tracker Project State

## Goal
Flutter mobile app for tracking borrowed and lent money.

## Stack
- Flutter
- Firebase Auth
- Firestore
- Provider
- Local Notifications

## Current Progress
- Flutter project created with folder structure (models, services, providers, screens, widgets, utils)
- Firebase dependencies added (firebase_core, firebase_auth, cloud_firestore, provider)
- Authentication implemented (Login/Register/Password Reset via Firebase Auth + Firestore user profile)
- AuthProvider with Provider state management
- AuthScreen (login/register toggle, form validation, error handling)
- HomeScreen placeholder with welcome message and sign-out
- main.dart entry point with Firebase init and AuthWrapper routing

## Architecture
- Feature-based folder structure
- Provider state management

## Pending Features
- <s>Authentication</s>
- CRUD entries
- Dashboard
- Notifications
- Statistics
- Offline support
- Export
- Security
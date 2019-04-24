# iOS Innovation Project
*April 2019*

A demo project for the iOS team to learn new technologies for an innovation exercise

## Overview

For this innovation exercise, we will be building an app in parallel, with each team member exploring the new technologies of his choosing. Each team member will have primary responsibility for one tab in the demo app, however we will be presenting the app as a team effort. Each person is encouraged to seek or provide help to anyone else. There should be no individual glory or credit for this project.

## Technologies

There are three main technologies that team members are encouraged to explore for this innovation exercise.

### 1. Apple Pencil integration

Look for interesting ways to leverage the Pencil to augment regular functionality. Investigate image, shape, or handwriting recognition possibilities. 

#### Resources

- WWDC: (10min) [Apple Pencil Design Essentials](https://developer.apple.com/videos/play/wwdc2018/809/)

### 2. Keyboard command support

Investigate options for global keyboard shortcuts. Find ways to trigger keyboard commands just by typing, à la Things. Figure out cancel (⌘.).

#### Resources

- [UIKeyCommand](https://developer.apple.com/documentation/uikit/uikeycommand)
- [NSHipster Article](https://nshipster.com/uikeycommand/)
- [UseYourLoaf Article](https://useyourloaf.com/blog/adding-hardware-keyboard-shortcuts/)

### 3. Highly interactive notifications.

Use custom actions, replacing actions while showing, and interactive elements in custom notification view. Build using CloudKit for push notifications.

#### Resources

- WWDC: [What's new in User Notifications](https://developer.apple.com/videos/play/wwdc2018/710/) 
- WWDC: [Designing Notifications](https://developer.apple.com/videos/play/wwdc2018/806/).)

## Technical Guidelines

### Third-party code

In general, avoid pulling in third-party code. This should be an exercise in building everything ourselves. Use discretion however, and feel free to pull in meaningful libraries that would significantly add functionality without incurring excessive overhead. If any code is pulled in, it should be copied in and committed. Any branch should be able to be checked out and the project built without downloading any dependencies.

### Branching strategy

The `master` branch should always be "releasable" (to TestFlight), or at least demoable. We will maintain a `dev` branch, and will only push to `master` from the `dev` branch. Individual branches can and should be created to work on features. Pull requests should be submitted from individual branches to the `dev` branch, and all changes should be merged from `dev` to the individual branches before submitting.

### File structure

The project has been structured to minimize the potential for merge conflicts. Each person will work on as assigned area of the project, as explained in [Individual Assignments](#individual-assignments). Changes to the shared folder should be communicated in Slack and made as early as possible to facilitate easier resolution of merge conflicts. Most changes and new files should occur and be saved in the designated folder for the assigned section.

## Individual Assignments

As mentioned in [Overview](#overview), each team member will be primarily responsible for one tab of the demo app. Functionality in that tab can be related to other tabs, but the idea is that they are all separate and distinct with no dependencies. The assignments are as follows:

1. **First:** Derik
2. **Second:** Parker
3. **Third:** Cole
4. **Fourth:** Ben P.
5. **Fifth:** Ben N.

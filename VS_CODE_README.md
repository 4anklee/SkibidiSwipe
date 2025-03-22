# Swift Swipe Game - VS Code Setup

This document explains how to use Visual Studio Code to develop, build, and run the Swift Swipe Game app.

## Setup Instructions

1. Install Visual Studio Code from https://code.visualstudio.com/

2. Install the required extensions:

    - [Swift](https://marketplace.visualstudio.com/items?itemName=sswg.swift-lang)
    - [CodeLLDB](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb)

3. Open the workspace file:
    - Launch VS Code
    - Choose File > Open Workspace from File...
    - Select the `swift-swipe-game.code-workspace` file

## Building and Running

### Building the App

1. Press `Cmd+Shift+B` (Mac) or `Ctrl+Shift+B` (Windows/Linux) to run the default build task
2. Alternatively, run the build task from the Command Palette (`Cmd+Shift+P` or `Ctrl+Shift+P`) by typing "Tasks: Run Build Task"

### Running in Simulator

#### Recommended Method:

1. Open the Command Palette (`Cmd+Shift+P`)
2. Type "Tasks: Run Task"
3. Select "Build, Open Simulator, and Run App"

This will:

-   Build the app
-   Open the iOS Simulator (iPhone 16 Pro)
-   Install and launch the app

#### Alternative Methods:

You can also run individual tasks for more control:

-   **Open Simulator and Run App**: Opens the simulator application with the correct device
-   **Install and Launch App in Simulator**: Installs and launches the app in a running simulator
-   **View Simulator Logs**: Shows real-time logs from the app running in the simulator

## Viewing Logs

To view logs from your app:

1. Open the Command Palette (`Cmd+Shift+P`)
2. Type "Tasks: Run Task"
3. Select "View Simulator Logs"

This will show a continuous stream of logs from your app.

## Project Structure

-   `.vscode/` - Contains VS Code configuration files
    -   `tasks.json` - Build and run tasks
    -   `launch.json` - Debug configurations
    -   `settings.json` - Editor and Swift extension settings
    -   `README.md` - More detailed information about VS Code setup

## Known Issues

-   Direct debugging with LLDB may result in breakpoint exceptions in the simulator
-   Use the "Build, Open Simulator, and Run App" task and "View Simulator Logs" task instead
-   CoreData warnings about "Remote Change Notification" are normal in the simulator

## Troubleshooting

-   If the build fails, ensure Xcode is installed and properly configured
-   If the simulator doesn't launch, verify the correct simulator is installed
-   If the app doesn't appear in the simulator, try running the "Install and Launch App in Simulator" task again
-   For best results, close any running simulators before starting new ones

# Support Page - Deployment Guide

This is a minimal support page for Drug Helper Kz that can be deployed to Firebase Hosting.

## Deployment Steps

1. **Initialize Firebase in this directory** (if not already done):
   ```bash
   cd support
   firebase init hosting
   ```
   - Select an existing Firebase project or create a new one
   - Set public directory to `.` (current directory)
   - Configure as single-page app: Yes
   - Set up automatic builds: No

2. **Deploy to Firebase Hosting**:
   ```bash
   firebase deploy --only hosting
   ```

## Alternative: Deploy to Different Firebase Project

If you want to deploy this to a completely separate Firebase project:

1. **Login to Firebase**:
   ```bash
   firebase login
   ```

2. **Initialize with a different project**:
   ```bash
   firebase use --add
   ```
   Select or create the project for your support site.

3. **Deploy**:
   ```bash
   firebase deploy --only hosting
   ```

## Customization

- **Email**: Update the email address in `index.html` (currently set to `jandaulet.coder@gmail.com`)
- **FAQ**: Modify the FAQ section in `index.html` to match your needs
- **Styling**: All styles are embedded in the `<style>` tag in `index.html`

## Features

- ✅ Minimal, clean design
- ✅ Mobile responsive
- ✅ Contact form with sending animation simulation
- ✅ Success message feedback
- ✅ FAQ section
- ✅ No external dependencies
- ✅ Single HTML file for easy deployment
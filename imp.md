# React Project Notes

## Context API

Use **Context API** when data needs to be shared across multiple components.

* `useState` → Local state (single component)
* `Context` → Global/shared state (multiple components)

---

## UI Libraries

### Shadcn UI

* Modern, customizable UI components.
* Built using Tailwind CSS.
* Used for buttons, dialogs, forms, cards, etc.

### Recharts

* React chart library.
* Used for Bar, Line, Pie, Area, and other charts.
* Easy integration with API data.

---

## Company Styled Emails

HTML email templates are used to send professional-looking emails.

* Responsive design
* Company branding
* Supports buttons, images, and formatting

---

## Send Mail Function

Email sending function is available inside the project.

> **Important:** Replace placeholder emails (e.g. `110`, `144`) with your own email address before deployment.

---

## Mail & Groq API

This project does **not** use a separate backend.

Flow:

```
Frontend
   ↓
POST Request
   ↓
Groq API
   ↓
Response
```

* Uses `POST` requests to communicate with Groq.
* No Express, Node backend, or server required.
* API key is used directly in the request (or via serverless functions if preferred).

---

## Summary

* **Context API** → Shared state management.
* **useState** → Local component state.
* **Shadcn UI** → UI components.
* **Recharts** → Data visualization.
* **HTML Emails** → Professional email templates.
* **Send Mail** → Replace placeholder emails with your own.
* **Groq API** → Accessed using POST requests without a dedicated backend.

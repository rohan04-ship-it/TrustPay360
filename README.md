# \# 🛡️ TrustPay 360

# 

# \### One Payment. Two-Sided Protection.

# 

# TrustPay 360 is a bilingual fintech prototype designed to improve digital payment safety, transparency, financial awareness, and dispute management for customers and merchants.

# 

# \## 🎯 Problem Statement

# 

# Digital payment users and merchants face several challenges:

# 

# \- Fraudulent and suspicious payment requests.

# \- Recipient identity mismatches.

# \- Misleading payment screenshots.

# \- Confusion caused by missing payment confirmations.

# \- Lack of organized dispute history.

# \- Limited financial and digital payment awareness.

# \- Language barriers in financial applications.

# 

# \## 💡 Our Solution

# 

# TrustPay 360 combines rule-based fraud-risk assessment, simulated two-sided payment verification, persistent dispute replay, and financial insights in a single bilingual application.

# 

# \## ✨ Key Features

# 

# | Feature | Description |

# |---|---|

# | Fraud Risk Checker | Calculates risk scores using predefined warning signals. |

# | Payment Requests | Create and save demo payment requests using Firebase. |

# | Demo Payment Verification | Simulates customer payments and merchant receipt verification. |

# | Dispute Replay | Displays recorded payment and dispute events. |

# | Financial Insights | Displays Firebase payment request totals and local budget and expense information. |

# | Firebase Authentication | Provides anonymous user authentication for the prototype. |

# | Payment History | Stores and retrieves saved payment requests. |

# | Bilingual Interface | Supports English and Kannada. |

# | Cross-Platform Support | Flutter application supporting Android and Web. |

# 

# \## 🛠️ Technology Stack

# 

# \- Frontend: Flutter

# \- Programming Language: Dart

# \- Backend: Firebase

# \- Database: Cloud Firestore

# \- Authentication: Firebase Authentication

# \- Development Environment: VS Code and Android Studio

# \- Version Control: Git and GitHub

# 

# \## 🏗️ System Architecture

# 

# ```text

# Customer / Merchant

# &#x20;       |

# &#x20;       v

# Flutter Application

# &#x20;       |

# &#x20;       +-- Rule-Based Risk Assessment

# &#x20;       +-- Demo Payment Verification

# &#x20;       +-- Financial Insights

# &#x20;       +-- Dispute Replay

# &#x20;       |

# &#x20;       v

# Firebase Authentication

# &#x20;       |

# &#x20;       v

# Cloud Firestore

# &#x20;       |

# &#x20;       +-- payment\_requests

# &#x20;               |

# &#x20;               +-- demo\_events

# ```

# 

# \## 🔄 Application Workflow

# 

# 1\. Merchant creates a demo payment request.

# 2\. Firebase stores the payment request.

# 3\. Customer checks payment risk indicators.

# 4\. Customer simulates a payment.

# 5\. Merchant simulates receipt verification.

# 6\. A matching or missing receipt event is recorded.

# 7\. Dispute events can be retrieved from Firebase.

# 8\. Financial Insights displays saved request totals.

# 

# \## 🔐 Security

# 

# \- Firebase anonymous authentication.

# \- Ownership-based Firestore access.

# \- Validated payment request fields.

# \- Append-only demo event records.

# \- Restricted client-side payment status modifications.

# 

# Anonymous authentication and simulated events do not establish verified customer or merchant identities.

# 

# \## 🌍 Social Impact

# 

# \- Promotes digital payment safety awareness.

# \- Encourages responsible financial decisions.

# \- Improves accessibility through Kannada language support.

# \- Demonstrates transparent dispute management.

# \- Supports financial literacy among customers and small merchants.

# 

# \## 🚀 Installation

# 

# Clone the repository:

# 

# ```bash

# git clone https://github.com/rohan04-ship-it/TrustPay360.git

# cd TrustPay360

# ```

# 

# Install dependencies:

# 

# ```bash

# flutter pub get

# ```

# 

# Run the web application:

# 

# ```bash

# flutter run -d chrome

# ```

# 

# Build the Android debug APK:

# 

# ```bash

# flutter build apk --debug

# ```

# 

# A compatible Flutter SDK, Android SDK, and configured Firebase project are required.

# 

# \## 🧪 Testing

# 

# ```bash

# flutter analyze

# flutter test

# ```

# 

# \## 🔮 Future Scope

# 

# \- Secure customer and merchant accounts.

# \- Authorized UPI and banking integrations.

# \- Machine-learning-based fraud detection.

# \- Dedicated dispute reviewer dashboard.

# \- Real-time payment notifications.

# \- Additional regional languages.

# \- Persistent personal expense and budget management.

# 

# \## ⚠️ Disclaimer

# 

# TrustPay 360 is an educational hackathon prototype. Payment transactions and merchant verification are simulated. No real money is transferred, and the application does not independently verify bank or UPI transactions.

# 

# \---

# 

# \*\*TrustPay 360 — Building trust on both sides of every payment.\*\*


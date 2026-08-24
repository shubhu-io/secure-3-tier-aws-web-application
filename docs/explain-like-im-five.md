# Explain This Project Like I'm Five 🧒

> A friendly, no-jargon version of the whole platform. Every section uses a
> simple everyday analogy. Great for interviewers, stakeholders, or just to
> check your own understanding.

---

## 1. The Big Idea

You have an **app** (like a game you can play in your browser) that people use
from all over the world. You want to:

- show it to everyone, even if thousands play at once,
- never lose your players' data,
- and be able to change the app **without breaking it**.

This project is a big, organized "toy box" that does all of that automatically.

---

## 2. The Three Pieces (the app's body parts)

Think of the app as a person:

| Body part | Real name | Job |
| --------- | --------- | --- |
| 👀 **Face** | Frontend (React) | The pretty part you see and click on. |
| 🧠 **Brain** | Backend (Node/Express) | Thinks: "You asked for a puppy? Here are 3 puppies." |
| 📚 **Memory** | Database (PostgreSQL) | Remembers everything: names, scores, pictures. |

A person needs all three. The app needs all three too.

---

## 3. Where It Lives (the cloud house)

Instead of one computer in someone's bedroom, the app lives in **AWS** — a huge
cloud where you can rent space. Our space is a **private house** (called a VPC)
with rooms:

- 🏠 **Living room (public room):** the front door — the *load balancer*. Everyone
  knocks here.
- 🚪 **Secret rooms (private rooms):** where the brain and memory live. Nobody can
  knock on their doors from the street.
- 🧱 **Guard wall (WAF):** checks every visitor — "Is this a friend? Or a robot
  trying to break in?" Bad guys get turned away at the door.

Why hide the brain and memory? Like a bank — the vault is in the back, not on
the sidewalk.

---

## 4. Why More Than One Copy? (auto scaling)

If one copy of your game gets tired, you make **another copy**. We keep **2
copies** (like 2 cashiers). If lots of people show up, the shop **automatically
adds more cashiers** (up to 4). When people leave, it puts the extra cashiers
away again. No one has to press any buttons — the shop just knows. 🪄

And if a cashier gets sick and leaves, a new one starts **automatically**, so the
shop never closes.

---

## 5. Where the Secret Password Lives (Secrets Manager)

The database has a secret password. We don't write it on a sticky note on the
wall (that would be in the code — bad!). Instead it's locked in a **tiny safe**,
and the app asks the safe for the password only when it starts. 🔐

---

## 6. The Magic Chain: Developer → Deployment

Imagine you made a new drawing and you want it in a book that everyone can see.

1. 🖊️ **You draw** — you write new code on your laptop.
2. 📦 **You put it in a mailbox** — you `git push`. (The mailbox is GitHub.)
3. 🤖 **The robot helper** (CI/CD pipeline) does the boring work for you:
   - Checks the drawing isn't broken (tests).
   - Puts the drawing in a nice frame (Docker image).
   - Gives it a **health check** — is the picture clean? Any germs (security
     bugs)? If yes, the robot **stops** and won't ship it. 🛑
4. 🛒 **Puts it on the shelf** — the framed drawing goes to the store
   (Amazon ECR).
5. 🏠 **Delivers to the house** — the app rooms swap the old drawing for the new
   one (that's the ASG refresh).
6. ✅ **Checks the door** — the robot knocks on the app and asks "Hello, is the
   new picture up?" If the app answers "Yes!" the new version is live.

**If something breaks**, the robot just puts the **old** picture back. No big
deal. ↩️

---

## 7. Watchdogs (monitoring)

We have a friendly **watchdog** (CloudWatch) that watches everything:

- "Is the brain too hot?" (CPU too high)
- "Is anyone knocking on a locked door?" (errors)
- "Is the memory getting full?" (disk space)

If something is wrong, the watchdog **barks** (SNS) — it sends an email to the
person who can fix it. 📧

---

## 8. The Rules of the House (security)

- No strangers on the street can touch the secret rooms.
- Every visitor is checked at the door (WAF).
- Only the app can talk to the database.
- All the important stuff is locked up and watched (encryption + logs).

In short: **lock everything, open only what's needed, and watch who comes in.**

---

## 9. The One-Page Story

> A developer draws a new picture. A robot checks it, frames it, and delivers it
> to a cloud house that always has a friendly person at the door, a brain in a
> secret room, a memory that never forgets, a watchdog that barks when things
> go wrong — and if the picture is bad, the robot puts the old one back.

---

## 10. "Five-Year-Old" Quick Reference

| Big word | Kid word |
| -------- | -------- |
| Frontend | the pretty face |
| Backend | the brain |
| Database | the memory |
| AWS cloud | the toy store you rent space from |
| VPC | the private house |
| Load balancer (ALB) | the front door + doorman |
| WAF | the guard who checks everyone |
| Docker image | a picture in a nice frame |
| ECR | the shelf where frames are stored |
| CI/CD pipeline | the robot helper |
| ASG | the shop that adds/removes cashiers |
| Secrets Manager | the tiny safe |
| CloudWatch | the watchdog |
| SNS | the watchdog's bark (email) |
| RDS | the memory that's always there |
| Terraform | the builder that draws the house's blueprints and builds it |

---

*See the full technical version in the main [README](../README.md).*

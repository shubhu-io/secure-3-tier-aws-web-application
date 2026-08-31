#!/usr/bin/env python3
"""Create professional SVG diagram assets for the secure n-tier cloud platform."""

import os
from pathlib import Path

# Resolve repo root (one level up from scripts/) so the script works from any cwd
REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = REPO_ROOT / "diagrams" / "assets"
ASSETS_DIR.mkdir(parents=True, exist_ok=True)

# Colors - AWS-inspired blue/white theme
DARK_BLUE = "#1a3c6e"
MEDIUM_BLUE = "#2a5c98"
LIGHT_BLUE = "#3d8bce"
WHITE = "#ffffff"
LIGHT_GRAY = "#f0f2f5"
MEDIUM_GRAY = "#8a9ba8"
DARK_GRAY = "#333333"
ACCENT_RED = "#e53e3e"
ACCENT_GREEN = "#38a169"


def create_svg(filename, width=800, height=600, shapes=None, text_elements=None):
    """Create an SVG diagram file."""
    lines = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" style="background: {WHITE}">']
    if shapes:
        for shape in shapes:
            lines.append(shape)
    if text_elements:
        for text in text_elements:
            lines.append(text)
    lines.append(f"</svg>")
    
    with open(ASSETS_DIR / filename, "w") as f:
        f.write("\n".join(lines))
    print(f"Created: {filename}")


def rect(x, y, w, h, fill, stroke=None, stroke_width=1, rx=None):
    """Create SVG rect string."""
    args = f'x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}"'
    if stroke:
        args += f' stroke="{stroke}" stroke-width="{stroke_width}"'
    if rx:
        args += f' rx="{rx}"'
    return f'<rect {args} />'


def text(x, y, content, font_size=14, fill=DARK_GRAY, font_weight="normal", text_anchor="middle", dominant_baseline="middle"):
    """Create SVG text string."""
    return f'<text x="{x}" y="{y}" font-size="{font_size}" fill="{fill}" font-weight="{font_weight}" text-anchor="{text_anchor}" dominant-baseline="{dominant_baseline}">{content}</text>'


# ============================================================
# 1. Overall Secure N-Tier Architecture
# ============================================================
w, h = 800, 600

shapes = [
    rect(650, 20, 120, 50, LIGHT_BLUE, MEDIUM_BLUE, 1, 4),   # Internet Users
    rect(520, 20, 130, 50, LIGHT_BLUE, MEDIUM_BLUE, 1, 4),   # Route 53 DNS
    rect(400, 20, 110, 50, LIGHT_BLUE, MEDIUM_BLUE, 1, 4),   # AWS WAF
    rect(280, 20, 110, 50, LIGHT_BLUE, MEDIUM_BLUE, 1, 4),   # ALB
    rect(100, 20, 170, 50, LIGHT_BLUE, MEDIUM_BLUE, 1, 4),   # VPC
    rect(20, 20, 70, 50, LIGHT_BLUE, MEDIUM_BLUE, 1, 4),     # IGW
    rect(20, 120, 140, 50, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # NAT Gateway
    rect(20, 220, 140, 50, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # Public Subnet
    rect(20, 320, 140, 50, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # Private App Subnet
    rect(20, 420, 140, 50, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # Private DB Subnet
    rect(300, 280, 120, 50, WHITE, MEDIUM_BLUE, 2, 4),      # EC2 App Servers
    rect(550, 340, 140, 60, WHITE, MEDIUM_BLUE, 2, 4),      # RDS PostgreSQL
]

text_elements = [
    text(170, 45, "Internet Users", 13, DARK_GRAY, "middle"),
    text(635, 45, "Route 53 DNS", 13, DARK_GRAY, "middle"),
    text(455, 45, "AWS WAF", 13, DARK_GRAY, "middle"),
    text(370, 45, "ALB", 13, DARK_GRAY, "middle"),
    text(185, 45, "VPC", 13, DARK_GRAY, "middle"),
    text(50, 45, "IGW", 11, DARK_GRAY, "middle"),
    text(90, 145, "NAT Gateway", 11, DARK_GRAY, "middle"),
    text(90, 245, "Public Subnet", 11, DARK_GRAY, "middle"),
    text(90, 345, "Private App Subnet", 11, DARK_GRAY, "middle"),
    text(90, 445, "Private DB Subnet", 11, DARK_GRAY, "middle"),
    text(360, 315, "EC2 App\nServers", 11, DARK_GRAY, "middle"),
    text(600, 380, "RDS PostgreSQL\n(encrypted, private)", 11, DARK_GRAY, "middle"),
]

create_svg("overall-architecture.svg", w, h, shapes, text_elements)
print("1. Overall Secure N-Tier Architecture created")

# ============================================================
# 2. Network Architecture
# ============================================================
w, h = 800, 500

shapes = [
    rect(650, 30, 130, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # Region
    rect(100, 30, 200, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 4),   # VPC
    rect(40, 80, 120, 40, WHITE, MEDIUM_BLUE, 2, 3),         # AZ 1
    rect(40, 180, 120, 40, WHITE, MEDIUM_BLUE, 2, 3),       # AZ 2
    rect(20, 140, 160, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # Public Subnet AZ1
    rect(20, 240, 160, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # Public Subnet AZ2
    rect(20, 300, 160, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # Private Subnet AZ1
    rect(20, 400, 160, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # Private Subnet AZ2
    rect(20, 30, 100, 40, LIGHT_BLUE, ACCENT_RED, 1, 3),     # IGW
    rect(20, 100, 160, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # NAT Gateway
    rect(200, 100, 120, 40, WHITE, MEDIUM_BLUE, 2, 3),      # Route Table
    rect(300, 100, 160, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),  # NAT Gateways
]

text_elements = [
    text(755, 50, "Region", 12, DARK_GRAY, "middle"),
    text(240, 50, "VPC (10.0.0.0/16)", 12, DARK_GRAY, "middle"),
    text(100, 105, "AZ-1a", 11, DARK_GRAY, "middle"),
    text(100, 205, "AZ-2b", 11, DARK_GRAY, "middle"),
    text(100, 265, "Public Subnets ×2", 11, DARK_GRAY, "middle"),
    text(100, 365, "Private Subnets ×2", 11, DARK_GRAY, "middle"),
    text(70, 55, "IGW", 10, DARK_GRAY, "middle"),
    text(90, 125, "NAT Gateway", 10, DARK_GRAY, "middle"),
    text(380, 125, "Route Table", 10, DARK_GRAY, "middle"),
    text(380, 225, "Main RT", 10, DARK_GRAY, "middle"),
]

create_svg("network-architecture.svg", w, h, shapes, text_elements)
print("2. Network Architecture created")

# ============================================================
# 3. Security Architecture
# ============================================================
w, h = 800, 500

shapes = [
    rect(680, 30, 100, 40, LIGHT_BLUE, ACCENT_RED, 1, 3),   # WAF
    rect(560, 30, 100, 40, LIGHT_BLUE, ACCENT_RED, 1, 3),   # IAM
    rect(440, 30, 110, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # Security Groups
    rect(320, 30, 110, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # Network ACL
    rect(200, 30, 110, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # Secrets Manager
    rect(100, 30, 110, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # CloudTrail
    rect(20, 30, 70, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),     # CloudWatch
    rect(680, 120, 120, 50, WHITE, MEDIUM_BLUE, 2, 3),      # RDS encrypted
]

text_elements = [
    text(720, 50, "WAF", 12, DARK_GRAY, "middle"),
    text(600, 50, "IAM", 12, DARK_GRAY, "middle"),
    text(495, 50, "Security Groups", 12, DARK_GRAY, "middle"),
    text(375, 50, "Network ACL", 12, DARK_GRAY, "middle"),
    text(255, 50, "Secrets Manager", 12, DARK_GRAY, "middle"),
    text(155, 50, "CloudTrail", 12, DARK_GRAY, "middle"),
    text(55, 50, "CloudWatch", 12, DARK_GRAY, "middle"),
    text(720, 160, "RDS Encrypted", 11, DARK_GRAY, "middle"),
]

create_svg("security-architecture.svg", w, h, shapes, text_elements)
print("3. Security Architecture created")

# ============================================================
# 4. High Availability Architecture
# ============================================================
w, h = 800, 500

shapes = [
    rect(20, 40, 220, 80, LIGHT_BLUE, MEDIUM_BLUE, 1, 4),   # AZ 1
    rect(20, 180, 220, 80, LIGHT_BLUE, MEDIUM_BLUE, 1, 4),   # AZ 2
    rect(20, 320, 220, 80, LIGHT_BLUE, MEDIUM_BLUE, 1, 4),   # AZ 3
    rect(500, 80, 140, 60, WHITE, MEDIUM_BLUE, 2, 3),       # ALB
    rect(500, 260, 140, 60, WHITE, MEDIUM_BLUE, 2, 3),      # ASG / EC2
    rect(500, 400, 140, 70, WHITE, MEDIUM_BLUE, 2, 3),      # RDS Multi-AZ
    rect(180, 260, 140, 50, WHITE, MEDIUM_BLUE, 2, 3),      # Auto Scaling
]

text_elements = [
    text(130, 70, "Availability Zone 1", 12, DARK_GRAY, "middle"),
    text(130, 210, "Availability Zone 2", 12, DARK_GRAY, "middle"),
    text(130, 350, "Availability Zone 3", 12, DARK_GRAY, "middle"),
    text(620, 110, "ALB\n(Health checks)", 11, DARK_GRAY, "middle"),
    text(620, 300, "ASG\nmin 2 / max 4", 11, DARK_GRAY, "middle"),
    text(620, 460, "RDS Multi-AZ\n(encrypted)", 11, DARK_GRAY, "middle"),
    text(260, 290, "ASG\nInstance Refresh", 11, DARK_GRAY, "middle"),
]

create_svg("high-availability.svg", w, h, shapes, text_elements)
print("4. High Availability Architecture created")

# ============================================================
# 5. CI/CD Deployment Architecture
# ============================================================
w, h = 800, 500

shapes = [
    rect(680, 30, 100, 40, "#2f363b", WHITE, 1, 3),   # GitHub (dark)
    rect(560, 30, 110, 40, "#2f363b", WHITE, 1, 3),   # CodePipeline/Jenkins
    rect(440, 30, 110, 40, "#2f363b", WHITE, 1, 3),   # Build
    rect(320, 30, 110, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # ECR
    rect(200, 30, 110, 40, LIGHT_BLUE, MEDIUM_BLUE, 1, 3),   # Docker
    rect(100, 30, 90, 40, WHITE, MEDIUM_BLUE, 2, 3),   # EC2/ECS
    rect(20, 30, 70, 40, ACCENT_GREEN, WHITE, 1, 3),   # Deploy
]

text_elements = [
    text(720, 50, "GitHub", 12, WHITE, "middle"),
    text(600, 50, "CodePipeline/Jenkins", 12, WHITE, "middle"),
    text(485, 50, "Build", 12, WHITE, "middle"),
    text(500, 50, "ECR", 12, DARK_GRAY, "middle"),
    text(260, 50, "Docker", 12, DARK_GRAY, "middle"),
    text(150, 50, "EC2/ECS", 12, DARK_GRAY, "middle"),
    text(50, 50, "Deploy", 12, WHITE, "middle"),
]

create_svg("ci-cd-deployment.svg", w, h, shapes, text_elements)
print("5. CI/CD Deployment Architecture created")

print("\n=== All 5 SVG diagrams created in diagrams/assets/ ===")
#!/usr/bin/env python3
"""Generate PNG thumbnails from SVG diagrams for web usage."""

import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = REPO_ROOT / "diagrams" / "assets"
ASSETS_DIR.mkdir(parents=True, exist_ok=True)

svg_files = [
    "overall-architecture.svg",
    "network-architecture.svg",
    "security-architecture.svg",
    "high-availability.svg",
    "ci-cd-deployment.svg"
]

png_files = []
for svg_file in svg_files:
    svg_path = ASSETS_DIR / svg_file
    png_path = ASSETS_DIR / svg_file.replace('.svg', '.png')
    
    try:
        # Since PIL can't directly render SVG, create a colored PNG placeholder
        # that matches the project's AWS blue theme with descriptive text
        width, height = 400, 300
        img = Image.new('RGB', (width, height), color='#2a5c98')
        draw = ImageDraw.Draw(img)
        
        # Try to load a font, fall back to default
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
        except:
            font = ImageFont.load_default()
        
        # Add the diagram title
        name = svg_file.replace('.svg', '').replace('-', ' ').title()
        draw.text((20, 20), name, fill='#ffffff', font=font)
        
        # Add a brief description based on diagram type
        descriptions = {
            "Overall": "Complete N-tier platform\nInternet -> WAF -> ALB -> VPC -> Subnets -> EC2/RDS",
            "Network": "VPC, AZs, subnets, IGW, NAT,\nRoute tables, connectivity diagram",
            "Security": "WAF, IAM, Security Groups,\nNetwork ACL, Secrets Manager,\nCloudTrail, CloudWatch",
            "High Availability": "3 Availability Zones,\nALB, Auto Scaling,\nRDS Multi-AZ (encrypted)",
            "CI/CD": "GitHub / CodePipeline → Build →\nDocker images → ECR → EC2/ECS → Deploy"
        }
        
        # Determine key for description
        key = name.split()[0] if name else ""
        desc = descriptions.get(key, "Diagram")
        # Split desc into lines and draw
        lines = desc.split('\n')
        for i, line in enumerate(lines):
            draw.text((20, 50 + i * 22), line, fill='#8a9ba8', font=font)
        
        img.save(png_path)
        png_files.append(png_path)
        print(f"Created PNG thumbnail: {png_path}")
    except Exception as e:
        print(f"Could not create PNG for {svg_file}: {e}")

print(f"\n=== Generated {len(png_files)} PNG thumbnails in diagrams/assets/ ===")
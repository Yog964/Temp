
filepath = r"d:\VIT\HackGenX\Version1.1\admin_dashboard\src\index.css"
leaflet_styles = """
/* LEAFLET WHITE MODE STYLES */
.leaflet-container {
    background: #f8fafc !important;
    border-radius: 12px;
}

.custom-pin {
    display: flex;
    align-items: center;
    justify-content: center;
}

.light-popup .leaflet-popup-content-wrapper {
    background: #ffffff !important;
    color: #1e293b !important;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

.light-popup .leaflet-popup-tip {
    background: #ffffff !important;
}
"""

with open(filepath, "a", encoding="utf-8") as f:
    f.write(leaflet_styles)

print("Added Leaflet White Mode styles to index.css")

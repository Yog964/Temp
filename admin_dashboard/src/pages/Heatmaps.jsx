import React, { useState, useEffect, useMemo } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import 'leaflet.heat';
import { fetchComplaints } from '../api';
import { MapPin, Droplets, Zap, Map as MapIcon, Trash2, Lightbulb, ShieldCheck, Filter, ZoomIn, Layers } from 'lucide-react';

// Leaflet default icon fix
import markerIcon from 'leaflet/dist/images/marker-icon.png';
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png';
import markerShadow from 'leaflet/dist/images/marker-shadow.png';

delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
    iconRetinaUrl: markerIcon2x,
    iconUrl: markerIcon,
    shadowUrl: markerShadow,
});

const HeatmapLayer = ({ points }) => {
    const map = useMap();

    useEffect(() => {
        if (!map || !points || points.length === 0) return;

        const heat = L.heatLayer(points, {
            radius: 25,
            blur: 15,
            maxZoom: 17,
            gradient: {
                0.4: 'blue',
                0.6: 'cyan',
                0.7: 'lime',
                0.8: 'yellow',
                1.0: 'red'
            }
        }).addTo(map);

        return () => {
            map.removeLayer(heat);
        };
    }, [map, points]);

    return null;
};

const getDeptIcon = (dept) => {
    const d = (dept || '').toLowerCase();
    if (d.includes('water')) return { color: '#2563eb', icon: Droplets };
    if (d.includes('elect')) return { color: '#ca8a04', icon: Zap };
    if (d.includes('road')) return { color: '#475569', icon: MapIcon };
    if (d.includes('waste')) return { color: '#92400e', icon: Trash2 };
    if (d.includes('light')) return { color: '#d97706', icon: Lightbulb };
    if (d.includes('sanit')) return { color: '#16a34a', icon: ShieldCheck };
    return { color: '#db2777', icon: MapPin };
};

const MapResizer = ({ points }) => {
    const map = useMap();
    useEffect(() => {
        if (points.length > 0) {
            const bounds = L.latLngBounds(points.map(p => [p[0], p[1]]));
            map.fitBounds(bounds, { padding: [50, 50] });
        }
    }, [points, map]);
    return null;
};

export default function Heatmaps() {
    const [complaints, setComplaints] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedDept, setSelectedDept] = useState('All');
    const [showHeatmap, setShowHeatmap] = useState(true);
    const [showMarkers, setShowMarkers] = useState(true);
    const [adminPos, setAdminPos] = useState([19.0760, 72.8777]);

    const departments = ['All', 'Water Supply', 'Electricity', 'Road & Infrastructure', 'Waste Management', 'Streetlight Maintenance', 'Sanitation'];

    useEffect(() => {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (pos) => {
                    setAdminPos([pos.coords.latitude, pos.coords.longitude]);
                },
                (err) => console.log("Geolocation error:", err)
            );
        }

        const load = async () => {
            const data = await fetchComplaints();
            const validData = data.filter(c => c.latitude && c.longitude);
            setComplaints(validData);
            setLoading(false);
        };
        load();
    }, []);

    const filteredComplaints = useMemo(() => {
        if (selectedDept === 'All') return complaints;
        return complaints.filter(c => c.department === selectedDept);
    }, [complaints, selectedDept]);

    const heatmapPoints = useMemo(() => {
        return filteredComplaints.map(c => [c.latitude, c.longitude, (c.severity_score || 5) / 10]);
    }, [filteredComplaints]);

    const MapController = ({ pos }) => {
        const map = useMap();
        useEffect(() => {
            if (pos) map.setView(pos, 13);
        }, [pos, map]);
        return null;
    };

    return (
        <div className="fade-in" style={{ height: 'calc(100vh - 160px)', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            <div className="page-header" style={{ marginBottom: 0 }}>
                <div>
                    <h2 className="title gradient-text">Smart City Geo-Intelligence</h2>
                    <p className="subtitle">Real-time geospatial visualization centering on your current location.</p>
                </div>
                <div style={{ display: 'flex', gap: '1rem' }}>
                    <button
                        className="btn-secondary"
                        onClick={() => {
                            if (navigator.geolocation) {
                                navigator.geolocation.getCurrentPosition((pos) => {
                                    setAdminPos([pos.coords.latitude, pos.coords.longitude]);
                                });
                            }
                        }}
                        style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                    >
                        <MapPin size={16} />
                        <span>My Location</span>
                    </button>
                    <div className="glass-panel" style={{ padding: '0.25rem 0.5rem', display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                        <Filter size={16} style={{ color: 'var(--primary-400)' }} />
                        <select
                            value={selectedDept}
                            onChange={(e) => setSelectedDept(e.target.value)}
                            className="search-input"
                            style={{ background: 'transparent', border: 'none', color: 'white', padding: '0.25rem', width: 'auto' }}
                        >
                            {departments.map(d => <option key={d} value={d} style={{ background: '#1e293b' }}>{d}</option>)}
                        </select>
                    </div>
                </div>
            </div>

            <div className="glass-panel" style={{ flex: 1, position: 'relative', overflow: 'hidden', padding: 0, border: '1px solid rgba(255,255,255,0.1)' }}>
                {loading ? (
                    <div style={{ height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <p className="subtitle">Mapping Active Incidents...</p>
                    </div>
                ) : (
                    <MapContainer
                        center={adminPos}
                        zoom={13}
                        style={{ height: '100%', width: '100%' }}
                    >
                        <TileLayer
                            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                        />
                        <MapController pos={adminPos} />

                        {showHeatmap && <HeatmapLayer points={heatmapPoints} />}

                        {showMarkers && filteredComplaints.map(c => {
                            const { color } = getDeptIcon(c.department);
                            const icon = L.divIcon({
                                className: 'custom-pin',
                                html: `<div style="background: ${color}; width: 14px; height: 14px; border-radius: 50%; border: 2px solid white; box-shadow: 0 0 10px ${color}"></div>`,
                                iconSize: [14, 14],
                            });

                            return (
                                <Marker key={c.id} position={[c.latitude, c.longitude]} icon={icon}>
                                    <Popup className="light-popup">
                                        <div style={{ minWidth: '180px' }}>
                                            <h4 style={{ margin: '0 0 5px 0', color: '#1e293b' }}>{c.title}</h4>
                                            <div style={{ fontSize: '0.8rem', color: '#64748b' }}>
                                                <p style={{ margin: '2px 0' }}><strong>Dept:</strong> {c.department}</p>
                                                <p style={{ margin: '2px 0' }}><strong>Status:</strong> {c.status}</p>
                                                {c.image_url && (
                                                    <img src={`http://localhost:8000/${c.image_url}`} style={{ width: '100%', borderRadius: '4px', marginTop: '8px' }} />
                                                )}
                                            </div>
                                        </div>
                                    </Popup>
                                </Marker>
                            );
                        })}

                        <MapResizer points={heatmapPoints} />
                    </MapContainer>
                )}

                {/* Controls overlay */}
                <div style={{ position: 'absolute', top: '20px', right: '20px', zIndex: 1000, display: 'flex', flexDirection: 'column', gap: '8px' }}>
                    <div className="glass-panel" style={{ padding: '8px' }}>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                            <button
                                className={`btn-secondary ${showHeatmap ? 'active' : ''}`}
                                onClick={() => setShowHeatmap(!showHeatmap)}
                                style={{ fontSize: '0.75rem', padding: '6px 12px', background: showHeatmap ? 'var(--primary-500)' : 'transparent' }}
                            >
                                Heatmap
                            </button>
                            <button
                                className={`btn-secondary ${showMarkers ? 'active' : ''}`}
                                onClick={() => setShowMarkers(!showMarkers)}
                                style={{ fontSize: '0.75rem', padding: '6px 12px', background: showMarkers ? 'var(--primary-500)' : 'transparent' }}
                            >
                                GPS Pins
                            </button>
                        </div>
                    </div>
                </div>

                <div className="glass-panel" style={{ position: 'absolute', bottom: '20px', left: '20px', zIndex: 1000, padding: '12px', fontSize: '0.75rem' }}>
                    <h5 style={{ margin: '0 0 8px 0', fontSize: '0.85rem' }}>Hotspot Categories</h5>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                        {departments.slice(1).map(d => (
                            <div key={d} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: getDeptIcon(d).color }}></div>
                                <span style={{ whiteSpace: 'nowrap' }}>{d.split(' ')[0]}</span>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}


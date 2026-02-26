import React, { useState, useEffect } from 'react';
import { Filter, AlertTriangle, MessageCircle, MapPin, Search, ChevronDown } from 'lucide-react';
import { fetchComplaints } from '../api';

export default function Complaints() {
    const [activeTab, setActiveTab] = useState('all');
    const [complaints, setComplaints] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const load = async () => {
            const data = await fetchComplaints();
            setComplaints(data);
            setLoading(false);
        };
        load();
    }, []);

    const filteredComplaints = complaints.filter(c => {
        if (activeTab === 'all') return true;
        if (activeTab === 'high-priority') return c.severity_score >= 8;
        if (activeTab === 'pending') return c.status === 'Pending';
        if (activeTab === 'resolved') return c.status === 'Resolved';
        return true;
    });

    return (
        <div className="fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            <div className="page-header" style={{ marginBottom: 0 }}>
                <div>
                    <h2 className="title gradient-text">Grievance Management</h2>
                    <p className="subtitle">Review, assign, and track reported civic issues.</p>
                </div>
                <div className="tab-container">
                    {['all', 'high-priority', 'pending', 'resolved'].map(tab => (
                        <button
                            key={tab}
                            onClick={() => setActiveTab(tab)}
                            className={`tab-btn ${activeTab === tab ? 'active' : ''}`}
                        >
                            {tab.replace('-', ' ')}
                        </button>
                    ))}
                </div>
            </div>

            <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.5rem' }}>
                <div className="search-bar" style={{ flex: 1, width: 'auto' }}>
                    <Search className="search-icon" />
                    <input
                        type="text"
                        placeholder="Search by ID, category, or location"
                        className="search-input"
                    />
                </div>
                <button className="btn-secondary">
                    <Filter size={20} />
                    <span>Filters</span>
                    <ChevronDown size={16} style={{ marginLeft: '0.5rem' }} />
                </button>
            </div>

            {loading ? (
                <div className="glass-panel" style={{ padding: '2rem', textAlign: 'center' }}>Loading complaints...</div>
            ) : (
                <div className="grid grid-cols-12" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '1.5rem' }}>
                    {filteredComplaints.map(complaint => (
                        <div key={complaint.id} className="glass-card complaint-card">
                            <div className="complaint-img-container">
                                <img
                                    src={`http://localhost:8000/${complaint.image_url}`}
                                    alt={complaint.issue_type}
                                    className="complaint-img"
                                    onError={(e) => {
                                        e.target.src = 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?auto=format&fit=crop&q=80&w=400';
                                    }}
                                />
                                <div className="complaint-badge">
                                    AI Match: {Math.round(complaint.confidence_score)}%
                                </div>
                            </div>

                            <div className="complaint-content">
                                <div className="complaint-header">
                                    <div>
                                        <span className="complaint-id">COMP-{complaint.id}</span>
                                        <h3 className="complaint-title">{complaint.issue_type || 'Unknown Issue'}</h3>
                                    </div>
                                    <div className={`complaint-priority priority-${complaint.severity_score >= 8 ? 'Critical' : 'High'}`}>
                                        {complaint.severity_score >= 8 ? 'Critical' : 'High'}
                                    </div>
                                </div>

                                <div className="complaint-details">
                                    <p className="complaint-detail-item">
                                        <MapPin size={16} /> Lat: {complaint.latitude}, Lng: {complaint.longitude}
                                    </p>
                                    <p className="complaint-detail-item" style={{ fontWeight: 'bold', color: 'var(--primary-400)' }}>
                                        Dept: {complaint.department}
                                    </p>
                                    {complaint.description && (
                                        <p className="complaint-detail-item" style={{ fontSize: '0.8rem', color: 'var(--gray-400)' }}>
                                            "{complaint.description}"
                                        </p>
                                    )}
                                    {complaint.voice_url && (
                                        <div className="complaint-detail-item" style={{ marginTop: '0.5rem' }}>
                                            <audio controls style={{ height: '30px', width: '100%' }}>
                                                <source src={`http://localhost:8000/${complaint.voice_url}`} type="audio/mpeg" />
                                            </audio>
                                        </div>
                                    )}
                                </div>

                                <div className="complaint-footer">
                                    <div className="complaint-meta">
                                        <p style={{ marginBottom: '0.25rem' }}>Status: {complaint.status}</p>
                                        <p>{new Date(complaint.created_at).toLocaleDateString()}</p>
                                    </div>
                                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                                        <button className="btn-outline">
                                            Reject
                                        </button>
                                        <button className="btn-small-primary">
                                            Assign Worker
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    ))}
                    {filteredComplaints.length === 0 && (
                        <div className="glass-panel" style={{ gridColumn: '1 / -1', padding: '3rem', textAlign: 'center' }}>
                            <h3 style={{ color: 'white' }}>No complaints found</h3>
                            <p className="subtitle">Reported issues will appear here after users upload them.</p>
                        </div>
                    )}
                </div>
            )}
        </div>
    );
}

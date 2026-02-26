import React, { useState } from 'react';
import { Filter, AlertTriangle, MessageCircle, MapPin, Search, ChevronDown } from 'lucide-react';

const mockComplaints = [
    {
        id: 'COMP-2024-0012',
        type: 'Pothole',
        category: 'Roads & Bridges',
        confidence: '94%',
        priority: 'High',
        priorityScore: 8.4,
        reporter: '+91 9876543210',
        location: 'MG Road, near Metro Pillar 42',
        date: '10 mins ago',
        status: 'Pending Assignment',
        votes: 24,
        image: 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?auto=format&fit=crop&q=80&w=400'
    },
    {
        id: 'COMP-2024-0045',
        type: 'Garbage Dump',
        category: 'Waste Mgmt',
        confidence: '88%',
        priority: 'Critical',
        priorityScore: 9.1,
        reporter: '+91 9876543211',
        location: 'Sector 14 Market Area',
        date: '1 hr ago',
        status: 'In Progress',
        votes: 56,
        image: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&q=80&w=400'
    }
];

export default function Complaints() {
    const [activeTab, setActiveTab] = useState('all');

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

            <div className="grid grid-cols-12" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '1.5rem' }}>
                {mockComplaints.map(complaint => (
                    <div key={complaint.id} className="glass-card complaint-card">
                        <div className="complaint-img-container">
                            <img src={complaint.image} alt={complaint.type} className="complaint-img" />
                            <div className="complaint-badge">
                                AI Match: {complaint.confidence}
                            </div>
                        </div>

                        <div className="complaint-content">
                            <div className="complaint-header">
                                <div>
                                    <span className="complaint-id">{complaint.id}</span>
                                    <h3 className="complaint-title">{complaint.type}</h3>
                                </div>
                                <div className={`complaint-priority priority-${complaint.priority}`}>
                                    {complaint.priority}
                                </div>
                            </div>

                            <div className="complaint-details">
                                <p className="complaint-detail-item">
                                    <MapPin size={16} /> {complaint.location}
                                </p>
                                <p className="complaint-detail-item">
                                    <AlertTriangle size={16} color="var(--primary-500)" /> AI Priority Score: {complaint.priorityScore}/10
                                </p>
                                <p className="complaint-detail-item">
                                    <MessageCircle size={16} /> {complaint.votes} Community Approvals
                                </p>
                            </div>

                            <div className="complaint-footer">
                                <div className="complaint-meta">
                                    <p style={{ marginBottom: '0.25rem' }}>Reporter: {complaint.reporter}</p>
                                    <p>{complaint.date}</p>
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
            </div>
        </div>
    );
}

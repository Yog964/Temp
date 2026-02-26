import React, { useState, useEffect } from 'react';
import { Filter, Search, ChevronDown, X, MapPin, Calendar, User, Info, FileText, Play, ThumbsUp } from 'lucide-react';
import { fetchComplaints, updateComplaintStatus } from '../api';

const BASE_URL = 'http://localhost:8000';

export default function Complaints() {
    const [activeTab, setActiveTab] = useState('all');
    const [complaints, setComplaints] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedComplaint, setSelectedComplaint] = useState(null);

    const load = async () => {
        setLoading(true);
        const data = await fetchComplaints();
        setComplaints(data);
        setLoading(false);
    };

    useEffect(() => {
        load();
    }, []);

    const handleUpdateStatus = async (id, status) => {
        const updated = await updateComplaintStatus(id, status);
        if (updated) {
            setSelectedComplaint(null);
            load();
        }
    };

    const filteredComplaints = complaints.filter(c => {
        if (activeTab === 'all') return true;
        if (activeTab === 'high-priority') return (c.severity_score || 0) >= 8;
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

            <div style={{ display: 'flex', gap: '1rem' }}>
                <div className="search-bar" style={{ flex: 1, width: 'auto' }}>
                    <Search className="search-icon" />
                    <input
                        type="text"
                        placeholder="Search by ID, category, or location..."
                        className="search-input"
                    />
                </div>
                <button className="btn-secondary">
                    <Filter size={20} />
                    <span>Filters</span>
                    <ChevronDown size={16} />
                </button>
            </div>

            {loading ? (
                <div className="glass-panel" style={{ padding: '3rem', textAlign: 'center' }}>Loading complaints...</div>
            ) : (
                <div className="glass-panel complaints-table-container">
                    <table className="complaints-table">
                        <thead>
                            <tr>
                                <th>Photo</th>
                                <th>Issue Type</th>
                                <th>Department</th>
                                <th>Location</th>
                                <th>Priority</th>
                                <th>Status</th>
                                <th>Votes</th>
                                <th>Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filteredComplaints.map(complaint => (
                                <tr
                                    key={complaint.id}
                                    className="complaint-row"
                                    onClick={() => setSelectedComplaint(complaint)}
                                >
                                    <td>
                                        <img
                                            src={`${BASE_URL}/${complaint.image_url}`}
                                            className="complaint-thumb"
                                            onError={(e) => e.target.src = 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?auto=format&fit=crop&q=80&w=400'}
                                        />
                                    </td>
                                    <td>
                                        <div style={{ fontWeight: '600' }}>{complaint.issue_type || complaint.title || 'Unknown'}</div>
                                        <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)' }}>ID: COMP-{complaint.id}</div>
                                    </td>
                                    <td>
                                        <span className="complaint-id" style={{ backgroundColor: 'rgba(59, 130, 246, 0.1)', color: 'var(--blue-400)' }}>
                                            {complaint.department}
                                        </span>
                                    </td>
                                    <td>
                                        <div style={{ fontSize: '0.85rem' }}>{complaint.latitude?.toFixed(4)}, {complaint.longitude?.toFixed(4)}</div>
                                    </td>
                                    <td>
                                        <div className={`complaint-priority priority-${(complaint.severity_score || 0) >= 8 ? 'Critical' : 'High'}`}>
                                            {(complaint.severity_score || 0) >= 8 ? 'Critical' : 'High'}
                                        </div>
                                    </td>
                                    <td>
                                        <span style={{ fontSize: '0.85rem', fontWeight: '500' }}>{complaint.status}</span>
                                    </td>
                                    <td>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', color: 'var(--primary-400)' }}>
                                            <ThumbsUp size={14} />
                                            <span>{complaint.votes || 0}</span>
                                        </div>
                                    </td>
                                    <td>
                                        <div style={{ fontSize: '0.85rem' }}>{new Date(complaint.created_at).toLocaleDateString()}</div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                    {filteredComplaints.length === 0 && (
                        <div style={{ padding: '3rem', textAlign: 'center' }}>
                            <h3 style={{ color: 'white' }}>No complaints found</h3>
                        </div>
                    )}
                </div>
            )}

            {/* DETAILS MODAL */}
            {selectedComplaint && (
                <div className="modal-overlay" onClick={() => setSelectedComplaint(null)}>
                    <div className="modal-content" onClick={e => e.stopPropagation()}>
                        <X className="modal-close" onClick={() => setSelectedComplaint(null)} />

                        <div style={{ display: 'grid', gridTemplateColumns: 'minmax(300px, 1fr) 1.5fr', height: '100%' }}>
                            <div style={{ padding: '2rem', borderRight: '1px solid rgba(255, 255, 255, 0.05)' }}>
                                <img
                                    src={`${BASE_URL}/${selectedComplaint.image_url}`}
                                    style={{ width: '100%', borderRadius: '1rem', objectFit: 'cover', marginBottom: '1.5rem', boxShadow: '0 10px 20px rgba(0,0,0,0.3)' }}
                                    onError={(e) => e.target.src = 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?auto=format&fit=crop&q=80&w=400'}
                                />
                                {selectedComplaint.voice_url && (
                                    <div className="glass-panel" style={{ padding: '1rem', marginBottom: '1.5rem' }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.75rem', color: 'var(--primary-400)' }}>
                                            <Play size={16} fill="currentColor" />
                                            <span style={{ fontWeight: '600' }}>Voice Recording</span>
                                        </div>
                                        <audio controls style={{ width: '100%', height: '35px' }}>
                                            <source src={`${BASE_URL}/${selectedComplaint.voice_url}`} type="audio/mpeg" />
                                        </audio>
                                    </div>
                                )}
                                <div className="btn-action-required" onClick={() => alert('User notification sent: Action required for this issue')}>
                                    Notification User Action
                                </div>
                            </div>

                            <div style={{ padding: '2rem', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                                <div>
                                    <h2 className="title" style={{ fontSize: '1.5rem', color: 'white', marginBottom: '0.5rem' }}>
                                        {selectedComplaint.issue_type || selectedComplaint.title}
                                    </h2>
                                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                                        <span className="complaint-id">COMP-{selectedComplaint.id}</span>
                                        <span className="complaint-id" style={{ backgroundColor: 'rgba(59, 130, 246, 0.1)', color: 'var(--blue-400)' }}>
                                            {selectedComplaint.department}
                                        </span>
                                    </div>
                                </div>

                                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                        <div style={{ padding: '0.75rem', backgroundColor: 'rgba(255,255,255,0.03)', borderRadius: '0.75rem' }}>
                                            <MapPin size={20} color="var(--primary-400)" />
                                        </div>
                                        <div>
                                            <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)' }}>Location</div>
                                            <div style={{ color: 'white' }}>{selectedComplaint.latitude}, {selectedComplaint.longitude}</div>
                                        </div>
                                    </div>

                                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                        <div style={{ padding: '0.75rem', backgroundColor: 'rgba(255,255,255,0.03)', borderRadius: '0.75rem' }}>
                                            <Calendar size={20} color="var(--primary-400)" />
                                        </div>
                                        <div>
                                            <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)' }}>Reported On</div>
                                            <div style={{ color: 'white' }}>{new Date(selectedComplaint.created_at).toLocaleString()}</div>
                                        </div>
                                    </div>

                                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                        <div style={{ padding: '0.75rem', backgroundColor: 'rgba(255,255,255,0.03)', borderRadius: '0.75rem' }}>
                                            <ThumbsUp size={20} color="var(--primary-400)" />
                                        </div>
                                        <div>
                                            <div style={{ fontSize: '0.75rem', color: 'var(--gray-500)' }}>Upvotes</div>
                                            <div style={{ color: 'white', fontWeight: 'bold' }}>{selectedComplaint.votes || 0} citizens voted</div>
                                        </div>
                                    </div>
                                </div>

                                <div className="glass-panel" style={{ padding: '1.5rem' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem', color: 'var(--primary-400)' }}>
                                        <FileText size={18} />
                                        <span style={{ fontWeight: '600' }}>Description</span>
                                    </div>
                                    <p style={{ color: 'var(--gray-300)', lineHeight: '1.6', fontSize: '0.95rem' }}>
                                        {selectedComplaint.description || "No description provided by user."}
                                    </p>
                                </div>

                                <div style={{ marginTop: 'auto', display: 'flex', gap: '1rem' }}>
                                    <button
                                        className="btn-secondary"
                                        style={{ flex: 1 }}
                                        onClick={() => handleUpdateStatus(selectedComplaint.id, 'Rejected')}
                                    >
                                        Reject Issue
                                    </button>
                                    <button
                                        className="btn-primary"
                                        style={{ flex: 1 }}
                                        onClick={() => handleUpdateStatus(selectedComplaint.id, 'In Progress')}
                                    >
                                        Assign To Worker
                                    </button>
                                    <button
                                        className="btn-primary"
                                        style={{ flex: 1, backgroundColor: 'var(--green-600)' }}
                                        onClick={() => handleUpdateStatus(selectedComplaint.id, 'Resolved')}
                                    >
                                        Mark Resolved
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}


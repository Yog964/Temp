import React, { useState, useEffect } from 'react';
import { Users, Phone, MapPin, Activity, Clock } from 'lucide-react';
import { fetchWorkers } from '../api';

export default function FieldWorkers() {
    const [workers, setWorkers] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const load = async () => {
            const data = await fetchWorkers();
            setWorkers(data);
            setLoading(false);
        };
        load();
    }, []);

    return (
        <div className="fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            <div className="page-header">
                <div>
                    <h2 className="title gradient-text">Field Staff Monitoring</h2>
                    <p className="subtitle">Track field workers and assigned resolution tasks.</p>
                </div>
                <button className="btn-primary">
                    Add New Worker
                </button>
            </div>

            {loading ? (
                <div className="glass-panel" style={{ padding: '2rem', textAlign: 'center' }}>Loading field staff...</div>
            ) : (
                <div className="grid grid-cols-3">
                    {workers.map(worker => (
                        <div key={worker.id} className="glass-card worker-card">
                            <div className="worker-card-bg"></div>

                            <div className="worker-header">
                                <div className="worker-profile">
                                    <div className="worker-avatar-wrap">
                                        <div className="worker-avatar">
                                            <span className="worker-avatar-text">{worker.name.charAt(0)}</span>
                                        </div>
                                    </div>
                                    <div className="worker-info">
                                        <h3 className="worker-name">{worker.name}</h3>
                                        <p className="worker-dept">{worker.department}</p>
                                    </div>
                                </div>
                                <div className={`worker-status status-${worker.status.replace(' ', '-')}`}>
                                    {worker.status === 'Active' && <span className="status-dot"></span>}
                                    {worker.status}
                                </div>
                            </div>

                            <div className="worker-details">
                                <div className="worker-detail-item">
                                    <Phone size={16} /> {worker.phone}
                                </div>
                                <div className="worker-detail-item">
                                    <MapPin size={16} /> {worker.location}
                                </div>
                                <div className="worker-stats">
                                    <div className="worker-stat-item">
                                        <Activity size={16} /> Active: <span className="worker-stat-val">{worker.active_tasks}</span>
                                    </div>
                                    <div className="worker-stat-item">
                                        <Clock size={16} /> Done: <span className="worker-stat-val">{worker.completed_tasks}</span>
                                    </div>
                                </div>
                            </div>

                            <div className="worker-actions">
                                <button className="btn-flex-outline">
                                    View Log
                                </button>
                                <button className="btn-flex-primary">
                                    Assign Task
                                </button>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}

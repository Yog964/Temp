import React from 'react';
import { Users, Phone, MapPin, Activity, Clock } from 'lucide-react';

const mockWorkers = [
    {
        id: 'WRK-01',
        name: 'Rajinder Kumar',
        department: 'Roads & Bridges',
        status: 'Active',
        activeTasks: 3,
        completedTasks: 45,
        rating: 4.8,
        phone: '+91 9876543100',
        location: 'Sector 14'
    },
    {
        id: 'WRK-02',
        name: 'Suresh Patil',
        department: 'Waste Mgmt',
        status: 'On Leave',
        activeTasks: 0,
        completedTasks: 82,
        rating: 4.9,
        phone: '+91 9876543101',
        location: 'N/A'
    },
    {
        id: 'WRK-03',
        name: 'Amit Sharma',
        department: 'Water Supply',
        status: 'Assigned',
        activeTasks: 1,
        completedTasks: 34,
        rating: 4.5,
        phone: '+91 9876543102',
        location: 'MG Road'
    }
];

export default function FieldWorkers() {
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

            <div className="grid grid-cols-3">
                {mockWorkers.map(worker => (
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
                                    <Activity size={16} /> Active: <span className="worker-stat-val">{worker.activeTasks}</span>
                                </div>
                                <div className="worker-stat-item">
                                    <Clock size={16} /> Done: <span className="worker-stat-val">{worker.completedTasks}</span>
                                </div>
                            </div>
                        </div>

                        <div className="worker-actions">
                            <button className="btn-flex-outline">
                                View Log
                            </button>
                            <button className="btn-flex-primary">
                                Assign Data
                            </button>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}

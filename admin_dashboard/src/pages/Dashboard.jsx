import React, { useState, useEffect } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { TrendingUp, AlertCircle, CheckCircle2, Clock } from 'lucide-react';
import { fetchStats } from '../api';

const chartData = [
    { name: 'Jan', value: 400 },
    { name: 'Feb', value: 300 },
    { name: 'Mar', value: 500 },
    { name: 'Apr', value: 200 },
    { name: 'May', value: 600 },
    { name: 'Jun', value: 400 },
    { name: 'Jul', value: 700 },
];

const StatCard = ({ title, value, icon: Icon, trend, colorClass }) => (
    <div className="glass-card stat-card">
        <div className={`stat-card-blur ${colorClass}-bg`}></div>
        <div className="stat-info">
            <p className="stat-title">{title}</p>
            <h3 className="stat-value">{value}</h3>
            <div className="stat-trend-wrap">
                <span className={`stat-trend ${colorClass}-bg ${colorClass}-text`}>
                    {trend}
                </span>
                <span className="stat-vs">vs last month</span>
            </div>
        </div>
        <div className={`stat-icon-wrap ${colorClass}-bg ${colorClass}-border ${colorClass}-shadow`}>
            <Icon size={24} className={`${colorClass}-text`} />
        </div>
    </div>
);

const DepartmentRow = ({ name, total, open, resolved, progress }) => (
    <div className="dept-row">
        <div className="flex-1">
            <h4 className="dept-name">{name}</h4>
            <div className="dept-stats">
                <span style={{ color: 'var(--gray-400)' }}>Total: {total}</span>
                <span style={{ color: 'var(--red-400)' }}>Open: {open}</span>
                <span style={{ color: 'var(--green-400)' }}>Resolved: {resolved}</span>
            </div>
        </div>
        <div className="dept-progress">
            <div className="dept-progress-info">
                <span style={{ color: 'var(--gray-400)' }}>SLA Compliance</span>
                <span style={{ color: 'var(--primary-400)', fontWeight: 'bold' }}>{progress}%</span>
            </div>
            <div className="progress-bar-bg">
                <div
                    className="progress-bar-fill"
                    style={{ width: `${progress}%` }}
                ></div>
            </div>
        </div>
    </div>
);

export default function Dashboard() {
    const [stats, setStats] = useState({ total: 0, critical: 0, resolutionRate: 0, avgSLA: '...' });

    useEffect(() => {
        const load = async () => {
            const data = await fetchStats();
            if (data) setStats(data);
        };
        load();
    }, []);

    return (
        <div className="fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <div className="page-header">
                <div>
                    <h2 className="title gradient-text">Overview</h2>
                    <p className="subtitle">Real-time status of civic operations and grievances.</p>
                </div>
                <button className="btn-primary">
                    Generate Report
                </button>
            </div>

            <div className="grid grid-cols-4">
                <StatCard title="Total Complaints" value={stats.total} icon={TrendingUp} trend="+12%" colorClass="color-primary" />
                <StatCard title="Critical Incidents" value={stats.critical} icon={AlertCircle} trend="-5%" colorClass="color-red" />
                <StatCard title="Resolution Rate" value={`${stats.resolutionRate}%`} icon={CheckCircle2} trend="+2%" colorClass="color-green" />
                <StatCard title="Avg SLA Time" value={stats.avgSLA} icon={Clock} trend="-1 hr" colorClass="color-blue" />
            </div>

            <div className="grid grid-cols-3">
                <div className="glass-panel" style={{ gridColumn: 'span 2', padding: '1.5rem' }}>
                    <div style={{ marginBottom: '1.5rem' }}>
                        <h3 style={{ fontSize: '1.25rem', fontWeight: 'bold', color: 'white' }}>Resolution Trends</h3>
                        <p className="subtitle">Monthly reported vs resolved</p>
                    </div>
                    <div style={{ height: '18rem', width: '100%' }}>
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={chartData}>
                                <defs>
                                    <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#14b8a6" stopOpacity={0.3} />
                                        <stop offset="95%" stopColor="#14b8a6" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" stroke="#ffffff10" vertical={false} />
                                <XAxis dataKey="name" stroke="#ffffff50" tick={{ fill: '#ffffff50', fontSize: 12 }} dy={10} axisLine={false} tickLine={false} />
                                <YAxis stroke="#ffffff50" tick={{ fill: '#ffffff50', fontSize: 12 }} dx={-10} axisLine={false} tickLine={false} />
                                <Tooltip
                                    contentStyle={{ backgroundColor: '#0f172a', borderColor: '#ffffff10', borderRadius: '12px' }}
                                    itemStyle={{ color: '#14b8a6' }}
                                />
                                <Area type="monotone" dataKey="value" stroke="#14b8a6" strokeWidth={3} fillOpacity={1} fill="url(#colorValue)" />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                <div className="glass-panel" style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column' }}>
                    <h3 style={{ fontSize: '1.25rem', fontWeight: 'bold', color: 'white', marginBottom: '1.5rem' }}>Department Ranking</h3>
                    <div className="custom-scrollbar" style={{ flex: 1, overflowY: 'auto', paddingRight: '0.5rem', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                        <DepartmentRow name="Water Supply" total="3,124" open="120" resolved="3,004" progress="96" />
                        <DepartmentRow name="Sanitation" total="4,500" open="450" resolved="4,050" progress="85" />
                        <DepartmentRow name="Electricity" total="2,100" open="300" resolved="1,800" progress="72" />
                        <DepartmentRow name="Roads & Bridges" total="1,800" open="600" resolved="1,200" progress="60" />
                        <DepartmentRow name="Waste Mgmt" total="876" open="50" resolved="826" progress="94" />
                    </div>
                </div>
            </div>

            {/* Mock Map View */}
            <div className="glass-panel map-container">
                <div className="map-bg-wrap">
                    <div className="map-bg-img"></div>

                    <div className="map-pin-red outer"></div>
                    <div className="map-pin-red inner"></div>

                    <div className="map-pin-yellow outer"></div>
                    <div className="map-pin-yellow inner"></div>
                </div>

                <div className="map-gradient"></div>

                <div className="map-overlay-top">
                    <h3 className="map-title">High-Risk Zones</h3>
                    <p className="map-subtitle">Live geospatial heatmap of critical grievances</p>
                </div>

                <div className="map-overlay-bottom">
                    <div className="glass-card map-legend-item">
                        <div className="map-legend-dot red"></div>
                        <span className="map-legend-text">Emergency (12)</span>
                    </div>
                    <div className="glass-card map-legend-item">
                        <div className="map-legend-dot yellow"></div>
                        <span className="map-legend-text">High Priority (45)</span>
                    </div>
                </div>
            </div>
        </div>
    );
}

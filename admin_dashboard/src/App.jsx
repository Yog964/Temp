import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, Users, AlertTriangle, Settings, Map, LogOut, Activity } from 'lucide-react';
import Dashboard from './pages/Dashboard';
import Complaints from './pages/Complaints';
import FieldWorkers from './pages/FieldWorkers';
import './index.css';

const Sidebar = () => {
  const location = useLocation();
  const navItems = [
    { path: '/', name: 'Dashboard', icon: LayoutDashboard },
    { path: '/complaints', name: 'Complaints', icon: AlertTriangle },
    { path: '/field-workers', name: 'Field Workers', icon: Users },
    { path: '/heatmaps', name: 'Heatmaps', icon: Map },
    { path: '/system', name: 'System Status', icon: Activity },
    { path: '/settings', name: 'Settings', icon: Settings },
  ];

  return (
    <div className="sidebar glass-panel">
      <div className="sidebar-header">
        <div className="logo-icon">
          <Activity />
        </div>
        <div>
          <h1 className="logo-text">UrbanSathi</h1>
          <p className="logo-subtext">Admin Portal</p>
        </div>
      </div>

      <nav className="nav-menu">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = location.pathname === item.path;
          return (
            <Link
              key={item.path}
              to={item.path}
              className={`nav-link ${isActive ? 'active' : ''}`}
            >
              <Icon size={20} />
              <span>{item.name}</span>
            </Link>
          );
        })}
      </nav>

      <div className="sidebar-footer">
        <button className="logout-btn">
          <LogOut size={20} />
          <span>Logout</span>
        </button>
      </div>
    </div>
  );
};

const Header = () => {
  return (
    <header className="header glass-panel">
      <div className="flex-1">
        <div className="search-bar">
          <input
            type="text"
            placeholder="Search complaints, IDs, or areas..."
            className="search-input"
          />
        </div>
      </div>
      <div className="user-profile">
        <div className="user-info">
          <p className="name">Commissioner</p>
          <p className="role">Super Admin</p>
        </div>
        <div className="avatar-wrapper">
          <div className="avatar">
            <Users />
          </div>
        </div>
      </div>
    </header>
  );
}

function App() {
  return (
    <Router>
      <div className="app-container">
        <Sidebar />
        <div className="main-wrapper">
          <div className="bg-overlay"></div>
          <div className="blob top-right"></div>
          <div className="blob bottom-left"></div>

          <Header />

          <main className="content-area">
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/complaints" element={<Complaints />} />
              <Route path="/field-workers" element={<FieldWorkers />} />
              <Route path="*" element={
                <div className="flex flex-col items-center justify-center h-full">
                  <h2 className="title gradient-text">Coming Soon</h2>
                  <p className="subtitle">This section is currently under development.</p>
                </div>
              } />
            </Routes>
          </main>
        </div>
      </div>
    </Router>
  );
}

export default App;

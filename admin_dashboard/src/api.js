const BASE_URL = 'http://localhost:8000';

export const fetchStats = async () => {
    const res = await fetch(`${BASE_URL}/complaints/`);
    if (!res.ok) return null;
    const complaints = await res.json();

    const critical = complaints.filter(c => c.severity_score >= 8).length;
    const resolved = complaints.filter(c => c.status === 'Resolved').length;

    return {
        total: complaints.length,
        critical,
        resolutionRate: complaints.length > 0 ? Math.round((resolved / complaints.length) * 100) : 0,
        avgSLA: '14 hrs', // Mocked for now
        complaints
    };
};

export const fetchComplaints = async () => {
    const res = await fetch(`${BASE_URL}/complaints/`);
    return res.ok ? await res.json() : [];
};

export const fetchWorkers = async () => {
    const res = await fetch(`${BASE_URL}/workers/`);
    return res.ok ? await res.json() : [];
};

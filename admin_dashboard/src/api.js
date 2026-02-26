const BASE_URL = 'http://localhost:8000';

export const fetchStats = async () => {
    const res = await fetch(`${BASE_URL}/complaints/`);
    if (!res.ok) return null;
    const complaints = await res.json();

    const critical = complaints.filter(c => c.severity_score >= 8).length;
    const resolvedCount = complaints.filter(c => c.status === 'Resolved').length;

    // Calculate department stats
    const departments = {};
    complaints.forEach(c => {
        const dept = c.department || 'Unassigned';
        if (!departments[dept]) {
            departments[dept] = { name: dept, total: 0, open: 0, resolved: 0 };
        }
        departments[dept].total++;
        if (c.status === 'Resolved') {
            departments[dept].resolved++;
        } else {
            departments[dept].open++;
        }
    });

    const deptStats = Object.values(departments).map(d => ({
        ...d,
        progress: d.total > 0 ? Math.round((d.resolved / d.total) * 100) : 0
    })).sort((a, b) => b.total - a.total);

    const topVoted = complaints.length > 0 ? [...complaints].sort((a, b) => (b.votes || 0) - (a.votes || 0))[0] : null;

    return {
        total: complaints.length,
        critical,
        resolutionRate: complaints.length > 0 ? Math.round((resolvedCount / complaints.length) * 100) : 0,
        avgSLA: '14 hrs',
        deptStats,
        topVoted,
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
export const updateComplaintStatus = async (id, status) => {
    const res = await fetch(`${BASE_URL}/complaints/${id}/status`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status })
    });
    return res.ok ? await res.json() : null;
};

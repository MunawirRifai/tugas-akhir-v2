import React, { useState, useEffect } from 'react';
import {
  LayoutDashboard, Users, Utensils, AlertCircle, Settings, LogOut,
  TrendingUp, BadgeCheck, Trash2, Calendar, Lock, Unlock, Clock,
  BarChart2, ShieldAlert, RefreshCw, Mail, Phone, User as UserIcon, X
} from 'lucide-react';
import './index.css';

const API_BASE_URL = 'http://103.67.78.39:8080/api/v1';

// API call helper
async function apiCall(endpoint, method = 'GET', body = null, token = null) {
  const headers = {
    'Content-Type': 'application/json',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const config = {
    method,
    headers,
  };
  if (body) {
    config.body = JSON.stringify(body);
  }

  const response = await fetch(`${API_BASE_URL}${endpoint}`, config);

  if (response.status === 401 || response.status === 403) {
    // If we get unauthorized on requests other than login, clear token
    if (endpoint !== '/auth/login') {
      localStorage.removeItem('adminToken');
      localStorage.removeItem('adminUser');
      window.location.reload();
      throw new Error('Sesi Anda telah berakhir. Silakan masuk kembali.');
    }
  }

  let json = {};
  const text = await response.text();
  if (text) {
    try {
      json = JSON.parse(text);
    } catch (e) {
      throw new Error(text || 'Gagal memproses permintaan');
    }
  }

  if (!response.ok) {
    throw new Error(json.message || 'Gagal memproses permintaan');
  }
  return json;
}

// --- Login Screen -- lock down admin auth ---
function LoginScreen({ onLoginSuccess }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    try {
      const response = await apiCall('/auth/login', 'POST', { email, password });
      const { user, access_token } = response.data;
      const role = user.role || 'ROLE_USER';

      if (role !== 'ROLE_ADMIN') {
        throw new Error('Akses ditolak. Akun Anda bukan Administrator.');
      }

      localStorage.setItem('adminToken', access_token);
      localStorage.setItem('adminUser', JSON.stringify(user));
      onLoginSuccess(access_token, user);
    } catch (err) {
      setError(err.message || 'Email atau password salah');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="login-container" style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh', backgroundColor: '#f3f4f6' }}>
      <div className="login-card" style={{ backgroundColor: 'white', padding: '40px', borderRadius: '12px', boxShadow: '0 4px 12px rgba(0,0,0,0.1)', width: '100%', maxWidth: '400px' }}>
        <div style={{ textAlign: 'center', marginBottom: '32px' }}>
          <div style={{ display: 'inline-flex', padding: '12px', borderRadius: '50%', backgroundColor: '#ecfdf5', marginBottom: '16px' }}>
            <Utensils size={36} color="#10b981" />
          </div>
          <h2 style={{ fontSize: '24px', fontWeight: 'bold', color: '#111827' }}>FoodAdmin</h2>
          <p style={{ color: '#6b7280', fontSize: '14px', marginTop: '4px' }}>Dashboard Pengelolaan Donasi Makanan</p>
        </div>

        {error && (
          <div style={{ backgroundColor: '#fee2e2', color: '#b91c1c', padding: '12px', borderRadius: '6px', fontSize: '14px', marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group" style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', fontSize: '14px', fontWeight: 500, color: '#374151', marginBottom: '6px' }}>Email Admin</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@email.com"
              required
              style={{ width: '100%', padding: '10px 14px', border: '1px solid #d1d5db', borderRadius: '6px', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div className="form-group" style={{ marginBottom: '24px' }}>
            <label style={{ display: 'block', fontSize: '14px', fontWeight: 500, color: '#374151', marginBottom: '6px' }}>Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
              style={{ width: '100%', padding: '10px 14px', border: '1px solid #d1d5db', borderRadius: '6px', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="btn-primary"
            style={{ width: '100%', padding: '12px', backgroundColor: '#10b981', color: 'white', border: 'none', borderRadius: '6px', fontWeight: 600, cursor: 'pointer', transition: 'background-color 0.2s' }}
          >
            {isLoading ? 'Masuk...' : 'Masuk ke Dashboard'}
          </button>
        </form>
      </div>
    </div>
  );
}

// --- Dashboard Overview Component ---
function DashboardScreen({ token }) {
  const [stats, setStats] = useState(null);
  const [recentFoods, setRecentFoods] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  const loadData = async () => {
    setError('');
    setIsLoading(true);
    try {
      const statsRes = await apiCall('/admin/dashboard-stats', 'GET', null, token);
      setStats(statsRes.data);

      const foodsRes = await apiCall('/admin/foods', 'GET', null, token);
      const sortedFoods = (foodsRes.data || []).sort((a, b) => b.id - a.id).slice(0, 5);
      setRecentFoods(sortedFoods);
    } catch (err) {
      setError(err.message || 'Gagal memuat statistik');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [token]);

  if (isLoading && !stats) {
    return <div style={{ padding: '24px', textAlign: 'center' }}>Memuat data statistik...</div>;
  }

  // Find most populated category
  let mostPopulatedCategory = '-';
  if (stats && stats.categoryStats) {
    let maxVal = -1;
    Object.entries(stats.categoryStats).forEach(([cat, val]) => {
      if (val > maxVal) {
        maxVal = val;
        mostPopulatedCategory = cat.charAt(0).toUpperCase() + cat.slice(1);
      }
    });
  }

  const chartData = stats?.categoryStats || {
    "makanan berat": 0,
    "minuman": 0,
    "sembako": 0,
    "kue snack": 0
  };

  const maxChartVal = Math.max(...Object.values(chartData), 5);

  return (
    <>
      <header className="top-bar">
        <div>
          <h1>Overview Admin</h1>
          <p style={{ color: 'var(--text-muted)' }}>Pantau aktivitas donasi makanan secara real-time</p>
        </div>
        <button className="action-btn" onClick={loadData} style={{ display: 'flex', alignItems: 'center', gap: '8px', backgroundColor: '#10b981', color: 'white', border: 'none', borderRadius: '6px', padding: '8px 16px', cursor: 'pointer' }}>
          <RefreshCw size={16} /> Segarkan Data
        </button>
      </header>

      {error && (
        <div style={{ backgroundColor: '#fee2e2', color: '#b91c1c', padding: '12px', borderRadius: '6px', fontSize: '14px', marginBottom: '20px' }}>
          {error}
        </div>
      )}

      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon green"><Utensils size={28} /></div>
          <div className="stat-details">
            <h3>Total Donasi</h3>
            <p>{stats?.totalFoods ?? 0}</p>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon blue"><Users size={28} /></div>
          <div className="stat-details">
            <h3>User Online (5m)</h3>
            <p>{stats?.onlineUsers ?? 0}</p>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon yellow"><TrendingUp size={28} /></div>
          <div className="stat-details">
            <h3>Total Pengguna</h3>
            <p>{stats?.totalUsers ?? 0}</p>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon purple"><BadgeCheck size={28} /></div>
          <div className="stat-details">
            <h3>Kategori Terbanyak</h3>
            <p style={{ fontSize: '18px', fontWeight: 'bold', marginTop: '4px' }}>{mostPopulatedCategory}</p>
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: '24px', marginTop: '24px' }}>
        {/* Latest Donations Table */}
        <section className="data-section" style={{ margin: 0 }}>
          <div className="section-header">
            <h2>Postingan Donasi Terbaru</h2>
          </div>
          <div className="table-wrapper">
            <table>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>DONATUR</th>
                  <th>NAMA MAKANAN</th>
                  <th>KATEGORI</th>
                  <th>STATUS</th>
                </tr>
              </thead>
              <tbody>
                {recentFoods.map((f) => (
                  <tr key={f.id}>
                    <td>#{f.id}</td>
                    <td style={{ fontWeight: 500 }}>{f.owner_name}</td>
                    <td>{f.food_name}</td>
                    <td style={{ textTransform: 'capitalize' }}>{f.category}</td>
                    <td>
                      <span className={`status-badge ${f.status.toLowerCase()}`}>
                        {f.status}
                      </span>
                    </td>
                  </tr>
                ))}
                {recentFoods.length === 0 && (
                  <tr>
                    <td colSpan="5" style={{ textAlign: 'center', padding: '20px', color: 'var(--text-muted)' }}>Belum ada postingan donasi</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>

        {/* Category Chart */}
        <section className="data-section" style={{ margin: 0 }}>
          <div className="section-header">
            <h2>Distribusi Donasi Per Kategori</h2>
            <p style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '4px' }}>Jumlah postingan makanan saat ini perkategori</p>
          </div>

          <div style={{ padding: '20px 0', height: '220px', display: 'flex', justifyContent: 'space-around', alignItems: 'flex-end', borderBottom: '1px solid var(--border-color)' }}>
            {Object.entries(chartData).map(([cat, val]) => {
              const heightPercent = (val / maxChartVal) * 100;
              let barColor = '#10b981'; // green for makanan berat
              if (cat === 'minuman') barColor = '#3b82f6'; // blue
              if (cat === 'sembako') barColor = '#f59e0b'; // yellow
              if (cat === 'kue snack') barColor = '#8b5cf6'; // purple
              if (cat === 'kompos') barColor = '#ef4444'; // red

              return (
                <div key={cat} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: '60px' }}>
                  <span style={{ fontSize: '12px', fontWeight: 'bold', marginBottom: '8px' }}>{val}</span>
                  <div style={{
                    width: '32px',
                    height: `${heightPercent}px`,
                    minHeight: val > 0 ? '8px' : '2px',
                    backgroundColor: barColor,
                    borderRadius: '4px 4px 0 0',
                    transition: 'height 0.6s ease'
                  }}></div>
                </div>
              );
            })}
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-around', marginTop: '12px' }}>
            {Object.keys(chartData).map((cat) => {
              let dotColor = '#10b981';
              if (cat === 'minuman') dotColor = '#3b82f6';
              if (cat === 'sembako') dotColor = '#f59e0b';
              if (cat === 'kue snack') dotColor = '#8b5cf6'; // purple
              if (cat === 'kompos') dotColor = '#ef4444'; // red

              const label = cat.charAt(0).toUpperCase() + cat.slice(1);

              return (
                <div key={cat} style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: dotColor }}></div>
                  <span style={{ fontSize: '10px', color: 'var(--text-muted)' }}>{label}</span>
                </div>
              );
            })}
          </div>
        </section>
      </div>
    </>
  );
}

// --- Donations List Screen Component ---
function DonationsScreen({ token }) {
  const [foods, setFoods] = useState([]);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('Semua');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  const loadFoods = async () => {
    setIsLoading(true);
    setError('');
    try {
      const res = await apiCall('/admin/foods', 'GET', null, token);
      setFoods(res.data || []);
    } catch (err) {
      setError(err.message || 'Gagal memuat daftar donasi');
    } finally {
      setIsLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Apakah Anda yakin ingin menghapus postingan donasi ini?')) return;
    try {
      await apiCall(`/admin/foods/${id}`, 'DELETE', null, token);
      alert('Postingan donasi berhasil dihapus');
      loadFoods();
    } catch (err) {
      alert('Gagal menghapus postingan: ' + err.message);
    }
  };

  useEffect(() => {
    loadFoods();
  }, [token]);

  const filteredFoods = foods.filter((f) => {
    const matchesSearch =
      (f.food_name || '').toLowerCase().includes(search.toLowerCase()) ||
      (f.owner_name || '').toLowerCase().includes(search.toLowerCase()) ||
      (f.address || '').toLowerCase().includes(search.toLowerCase());

    const matchesStatus =
      statusFilter === 'Semua' ||
      (f.status || '').toUpperCase() === statusFilter.toUpperCase();

    return matchesSearch && matchesStatus;
  });

  return (
    <>
      <header className="top-bar">
        <div>
          <h1>Data Donasi Makanan</h1>
          <p style={{ color: 'var(--text-muted)' }}>Manajemen semua postingan donasi makanan</p>
        </div>
      </header>

      {error && (
        <div style={{ backgroundColor: '#fee2e2', color: '#b91c1c', padding: '12px', borderRadius: '6px', fontSize: '14px', marginBottom: '20px' }}>
          {error}
        </div>
      )}

      <section className="data-section">
        <div style={{ display: 'flex', gap: '16px', marginBottom: '24px', alignItems: 'center' }}>
          <input
            type="text"
            placeholder="Cari makanan, donatur, atau alamat..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ flex: 1, padding: '10px 14px', border: '1px solid var(--border-color)', borderRadius: '8px', fontSize: '14px', outline: 'none' }}
          />
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            style={{ padding: '10px 14px', border: '1px solid var(--border-color)', borderRadius: '8px', fontSize: '14px', outline: 'none', minWidth: '150px' }}
          >
            <option value="Semua">Semua Status</option>
            <option value="POSTED">POSTED</option>
            <option value="ON_THE_WAY">ON_THE_WAY</option>
            <option value="PICKED_UP">PICKED_UP</option>
            <option value="COMPLETED">COMPLETED</option>
            <option value="CANCELED">CANCELED</option>
          </select>
        </div>

        {isLoading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}>Memuat daftar donasi...</div>
        ) : (
          <div className="table-wrapper">
            <table>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>ITEM MAKANAN</th>
                  <th>DONATUR</th>
                  <th>ALAMAT PENJEMPUTAN</th>
                  <th>SISA / TOTAL STOK</th>
                  <th>STATUS</th>
                  <th>AKSI</th>
                </tr>
              </thead>
              <tbody>
                {filteredFoods.map((f) => (
                  <tr key={f.id}>
                    <td>#{f.id}</td>
                    <td>
                      <div style={{ fontWeight: 600, color: '#1f2937' }}>{f.food_name}</div>
                      <div style={{ fontSize: '12px', color: 'var(--text-muted)', textTransform: 'capitalize' }}>{f.category}</div>
                    </td>
                    <td>
                      <div style={{ fontWeight: 500 }}>{f.owner_name}</div>
                      <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>{f.owner_phone || '-'}</div>
                    </td>
                    <td style={{ fontSize: '13px', maxWidth: '200px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={f.address}>
                      {f.address}
                    </td>
                    <td>{f.quantity} / {f.original_quantity}</td>
                    <td>
                      <span className={`status-badge ${f.status.toLowerCase()}`}>
                        {f.status}
                      </span>
                    </td>
                    <td>
                      <button className="action-btn danger" onClick={() => handleDelete(f.id)} style={{ display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                        <Trash2 size={14} /> Hapus
                      </button>
                    </td>
                  </tr>
                ))}
                {filteredFoods.length === 0 && (
                  <tr>
                    <td colSpan="7" style={{ textAlign: 'center', padding: '20px', color: 'var(--text-muted)' }}>Postingan makanan tidak ditemukan</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </>
  );
}

// --- Users List Screen Component ---
function UsersScreen({ token, currentUser }) {
  const [users, setUsers] = useState([]);
  const [search, setSearch] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [showTimeoutModal, setShowTimeoutModal] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);
  const [timeoutHours, setTimeoutHours] = useState('1');

  const loadUsers = async () => {
    setIsLoading(true);
    setError('');
    try {
      const res = await apiCall('/admin/users', 'GET', null, token);
      setUsers(res.data || []);
    } catch (err) {
      setError(err.message || 'Gagal memuat daftar pengguna');
    } finally {
      setIsLoading(false);
    }
  };

  const handleBan = async (id) => {
    try {
      await apiCall(`/admin/users/${id}/ban`, 'POST', null, token);
      loadUsers();
    } catch (err) {
      alert('Gagal memperbarui status blokir: ' + err.message);
    }
  };

  const handleTimeoutSubmit = async (e) => {
    e.preventDefault();
    if (!selectedUser) return;
    try {
      await apiCall(`/admin/users/${selectedUser.id}/timeout`, 'POST', { hours: parseInt(timeoutHours) }, token);
      setShowTimeoutModal(false);
      setSelectedUser(null);
      loadUsers();
    } catch (err) {
      alert('Gagal menyetel timeout: ' + err.message);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Apakah Anda yakin ingin menghapus pengguna ini? Semua data postingan dan klaim miliknya juga akan dihapus.')) return;
    try {
      await apiCall(`/admin/users/${id}`, 'DELETE', null, token);
      alert('Pengguna berhasil dihapus');
      loadUsers();
    } catch (err) {
      alert('Gagal menghapus pengguna: ' + err.message);
    }
  };

  useEffect(() => {
    loadUsers();
  }, [token]);

  const filteredUsers = users.filter((u) => {
    return (
      (u.fullName || '').toLowerCase().includes(search.toLowerCase()) ||
      (u.email || '').toLowerCase().includes(search.toLowerCase()) ||
      (u.phone || '').toLowerCase().includes(search.toLowerCase())
    );
  });

  return (
    <>
      <header className="top-bar">
        <div>
          <h1>Pengguna Aplikasi</h1>
          <p style={{ color: 'var(--text-muted)' }}>Manajemen reputasi, penangguhan, dan pemblokiran pengguna</p>
        </div>
      </header>

      {error && (
        <div style={{ backgroundColor: '#fee2e2', color: '#b91c1c', padding: '12px', borderRadius: '6px', fontSize: '14px', marginBottom: '20px' }}>
          {error}
        </div>
      )}

      <section className="data-section">
        <div style={{ marginBottom: '24px' }}>
          <input
            type="text"
            placeholder="Cari pengguna berdasarkan nama, email, atau telepon..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ width: '100%', padding: '10px 14px', border: '1px solid var(--border-color)', borderRadius: '8px', fontSize: '14px', outline: 'none' }}
          />
        </div>

        {isLoading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}>Memuat daftar pengguna...</div>
        ) : (
          <div className="table-wrapper">
            <table>
              <thead>
                <tr>
                  <th>PENGGUNA</th>
                  <th>KONTAK</th>
                  <th>PERAN (ROLE)</th>
                  <th>STATUS KEAKTIFAN</th>
                  <th>STATISTIK</th>
                  <th>STATUS BLOKIR / TIMEOUT</th>
                  <th>AKSI</th>
                </tr>
              </thead>
              <tbody>
                {filteredUsers.map((u) => {
                  const isSelf = currentUser && String(currentUser.id) === String(u.id);

                  // Calculate online status (active in the last 5 minutes)
                  const isOnline = u.lastActiveAt && (new Date(u.lastActiveAt) > new Date(Date.now() - 5 * 60 * 1000));

                  // Calculate timeout remaining
                  const isTimeout = u.timeoutUntil && (new Date(u.timeoutUntil) > new Date());
                  const formattedRole = u.role === 'ROLE_ADMIN' ? 'Admin' : 'User Flutter';

                  return (
                    <tr key={u.id}>
                      <td>
                        <div style={{ fontWeight: 600, color: '#1f2937' }}>{u.fullName}</div>
                        <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>ID: #{u.id}</div>
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px' }}>
                          <Mail size={12} color="var(--text-muted)" /> {u.email}
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', marginTop: '2px' }}>
                          <Phone size={12} color="var(--text-muted)" /> {u.phone}
                        </div>
                      </td>
                      <td>
                        <span className={`role-badge ${u.role === 'ROLE_ADMIN' ? 'admin' : 'user'}`} style={{
                          padding: '4px 8px',
                          borderRadius: '12px',
                          fontSize: '11px',
                          fontWeight: 500,
                          backgroundColor: u.role === 'ROLE_ADMIN' ? '#f3e8ff' : '#f3f4f6',
                          color: u.role === 'ROLE_ADMIN' ? '#6b21a8' : '#374151'
                        }}>
                          {formattedRole}
                        </span>
                      </td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                          <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: isOnline ? '#10b981' : '#9ca3af' }}></div>
                          <span style={{ fontSize: '12px', color: '#4b5563' }}>{isOnline ? 'Online' : 'Offline'}</span>
                        </div>
                      </td>
                      <td>
                        <div style={{ fontSize: '12px' }}>Donasi: <strong>{u.totalDonations}x</strong></div>
                        <div style={{ fontSize: '12px' }}>Claim: <strong>{u.totalClaims}x</strong></div>
                      </td>
                      <td>
                        {u.isBanned ? (
                          <span className="status-badge resolved" style={{ backgroundColor: '#fee2e2', color: '#b91c1c' }}>Banned</span>
                        ) : isTimeout ? (
                          <span className="status-badge on_the_way" style={{ backgroundColor: '#fef3c7', color: '#d97706' }}>
                            Timeout
                          </span>
                        ) : (
                          <span className="status-badge" style={{ backgroundColor: '#d1fae5', color: '#065f46' }}>Aktif</span>
                        )}
                      </td>
                      <td>
                        <div style={{ display: 'flex', gap: '8px' }}>
                          <button
                            disabled={isSelf}
                            className={`action-btn ${u.isBanned ? 'success' : 'danger'}`}
                            onClick={() => handleBan(u.id)}
                            style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', opacity: isSelf ? 0.5 : 1 }}
                          >
                            <Lock size={12} /> {u.isBanned ? 'Unban' : 'Ban'}
                          </button>

                          <button
                            disabled={isSelf}
                            className="action-btn"
                            onClick={() => {
                              setSelectedUser(u);
                              setTimeoutHours(isTimeout ? '0' : '1');
                              setShowTimeoutModal(true);
                            }}
                            style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', color: '#2563eb', border: '1px solid #bfdbfe', opacity: isSelf ? 0.5 : 1 }}
                          >
                            <Clock size={12} /> Timeout
                          </button>

                          {!isSelf && u.role !== 'ROLE_ADMIN' && (
                            <button
                              className="action-btn danger"
                              onClick={() => handleDelete(u.id)}
                              style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', padding: '4px 8px' }}
                            >
                              <Trash2 size={12} /> Hapus
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {/* Timeout Hours Modal Dialog */}
      {showTimeoutModal && selectedUser && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 }}>
          <div style={{ backgroundColor: 'white', padding: '24px', borderRadius: '12px', width: '90%', maxWidth: '400px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <h3 style={{ fontSize: '18px', fontWeight: 'bold' }}>Set Timeout untuk {selectedUser.fullName}</h3>
              <button onClick={() => { setShowTimeoutModal(false); setSelectedUser(null); }} style={{ background: 'none', border: 'none', cursor: 'pointer' }}><X size={20} /></button>
            </div>
            <form onSubmit={handleTimeoutSubmit}>
              <div style={{ marginBottom: '20px' }}>
                <label style={{ display: 'block', fontSize: '14px', marginBottom: '8px' }}>Pilih Durasi Penangguhan (Timeout):</label>
                <select
                  value={timeoutHours}
                  onChange={(e) => setTimeoutHours(e.target.value)}
                  style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #d1d5db', outline: 'none' }}
                >
                  <option value="0">Hapus Penangguhan (Aktifkan Kembali)</option>
                  <option value="1">1 Jam</option>
                  <option value="3">3 Jam</option>
                  <option value="12">12 Jam</option>
                  <option value="24">24 Jam (1 Hari)</option>
                  <option value="72">72 Jam (3 Hari)</option>
                  <option value="168">168 Jam (7 Hari)</option>
                </select>
              </div>
              <div style={{ display: 'flex', justifyContent: 'end', gap: '12px' }}>
                <button type="button" onClick={() => { setShowTimeoutModal(false); setSelectedUser(null); }} style={{ padding: '8px 16px', border: '1px solid #d1d5db', borderRadius: '6px', background: 'none', cursor: 'pointer' }}>Batal</button>
                <button type="submit" style={{ padding: '8px 16px', backgroundColor: '#3b82f6', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer' }}>Simpan</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}

// --- Settings Screen Component ---
function SettingsScreen() {
  const [csLink, setCsLink] = useState(localStorage.getItem('csLink') || 'https://wa.me/6281234567890');
  const [defaultExpiry, setDefaultExpiry] = useState(localStorage.getItem('defaultExpiry') || '24');

  const handleSave = () => {
    localStorage.setItem('csLink', csLink);
    localStorage.setItem('defaultExpiry', defaultExpiry);
    alert('Konfigurasi aplikasi berhasil disimpan!');
  };

  return (
    <>
      <header className="top-bar">
        <div>
          <h1>Pengaturan</h1>
          <p style={{ color: 'var(--text-muted)' }}>Konfigurasi sistem dan bantuan CS</p>
        </div>
      </header>

      <div className="settings-grid" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
        <section className="data-section" style={{ margin: 0 }}>
          <div className="section-header">
            <h2>Profil Admin</h2>
          </div>
          <div className="form-group" style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', fontSize: '14px', marginBottom: '6px' }}>Nama Administrator</label>
            <input type="text" defaultValue="Super Administrator" readOnly style={{ width: '100%', padding: '10px', border: '1px solid #d1d5db', borderRadius: '6px', backgroundColor: '#f9fafb' }} />
          </div>
          <div className="form-group">
            <label style={{ display: 'block', fontSize: '14px', marginBottom: '6px' }}>Email Kontak</label>
            <input type="email" defaultValue="admin@email.com" readOnly style={{ width: '100%', padding: '10px', border: '1px solid #d1d5db', borderRadius: '6px', backgroundColor: '#f9fafb' }} />
          </div>
        </section>

        <section className="data-section" style={{ margin: 0 }}>
          <div className="section-header">
            <h2>Konfigurasi Aplikasi</h2>
          </div>
          <div className="form-group" style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', fontSize: '14px', marginBottom: '6px' }}>Link WhatsApp Bantuan (CS)</label>
            <input type="text" value={csLink} onChange={(e) => setCsLink(e.target.value)} style={{ width: '100%', padding: '10px', border: '1px solid #d1d5db', borderRadius: '6px', outline: 'none' }} />
          </div>
          <div className="form-group" style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', fontSize: '14px', marginBottom: '6px' }}>Waktu Batas Kedaluwarsa Default (Jam)</label>
            <input type="number" value={defaultExpiry} onChange={(e) => setDefaultExpiry(e.target.value)} style={{ width: '100%', padding: '10px', border: '1px solid #d1d5db', borderRadius: '6px', outline: 'none' }} />
          </div>
          <button className="btn-primary" onClick={handleSave} style={{ backgroundColor: '#10b981', color: 'white', padding: '10px 20px', border: 'none', borderRadius: '6px', fontWeight: 600, cursor: 'pointer' }}>
            Simpan Konfigurasi
          </button>
        </section>
      </div>
    </>
  );
}

// --- Main App Wrapper ---
function App() {
  const [token, setToken] = useState(localStorage.getItem('adminToken') || '');
  const [currentUser, setCurrentUser] = useState(null);
  const [activeTab, setActiveTab] = useState('dashboard');

  useEffect(() => {
    const storedUser = localStorage.getItem('adminUser');
    if (storedUser) {
      setCurrentUser(JSON.parse(storedUser));
    }
  }, [token]);

  const handleLogout = () => {
    if (!window.confirm('Apakah Anda yakin ingin keluar?')) return;
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminUser');
    setToken('');
    setCurrentUser(null);
  };

  if (!token) {
    return <LoginScreen onLoginSuccess={(tok, user) => { setToken(tok); setCurrentUser(user); }} />;
  }

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard': return <DashboardScreen token={token} />;
      case 'donations': return <DonationsScreen token={token} />;
      case 'users': return <UsersScreen token={token} currentUser={currentUser} />;
      case 'settings': return <SettingsScreen />;
      default: return <DashboardScreen token={token} />;
    }
  };

  return (
    <div className="app-container">
      {/* Sidebar Navigation */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <Utensils size={28} color="#10b981" />
          <h2>FoodAdmin</h2>
        </div>
        <nav className="nav-links">
          <button
            className={`nav-item ${activeTab === 'dashboard' ? 'active' : ''}`}
            onClick={() => setActiveTab('dashboard')}
          >
            <LayoutDashboard size={20} /> Dashboard
          </button>
          <button
            className={`nav-item ${activeTab === 'donations' ? 'active' : ''}`}
            onClick={() => setActiveTab('donations')}
          >
            <Utensils size={20} /> Data Donasi
          </button>
          <button
            className={`nav-item ${activeTab === 'users' ? 'active' : ''}`}
            onClick={() => setActiveTab('users')}
          >
            <Users size={20} /> Pengguna
          </button>
          <button
            className={`nav-item ${activeTab === 'settings' ? 'active' : ''}`}
            onClick={() => setActiveTab('settings')}
            style={{ marginTop: 'auto' }}
          >
            <Settings size={20} /> Pengaturan
          </button>
          <button className="nav-item" onClick={handleLogout} style={{ color: '#ef4444' }}>
            <LogOut size={20} /> Keluar
          </button>
        </nav>
      </aside>

      {/* Main Content Pane */}
      <main className="main-content">
        {renderContent()}
      </main>
    </div>
  );
}

export default App;
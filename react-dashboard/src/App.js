import React, { useState, useEffect } from 'react';
import { Layout, Card, Table, Tag, Statistic, Row, Col, Alert, Spin } from 'antd';
import { SecurityScanOutlined, WarningOutlined, CheckCircleOutlined, CloseCircleOutlined } from '@ant-design/icons';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, BarChart, Bar, PieChart, Pie, Cell } from 'recharts';
import './App.css';

const { Header, Content, Sider } = Layout;

function App() {
  const [findings, setFindings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    total: 0,
    high: 0,
    medium: 0,
    low: 0,
    critical: 0
  });

  useEffect(() => {
    fetchFindings();
    const interval = setInterval(fetchFindings, 30000); // Refresh every 30 seconds
    return () => clearInterval(interval);
  }, []);

  const fetchFindings = async () => {
    try {
      // In a real implementation, this would call your backend API
      // For demo purposes, we'll use mock data
      const mockFindings = [
        {
          id: '1',
          type: 'Recon:EC2/PortProbeUnprotectedPort',
          severity: 8.5,
          title: 'Port probe detected on unprotected port',
          description: 'EC2 instance is being probed on port 22',
          region: 'us-east-1',
          timestamp: new Date().toISOString(),
          resource: { instanceId: 'i-1234567890abcdef0' },
          status: 'ACTIVE'
        },
        {
          id: '2',
          type: 'Backdoor:EC2/Spambot',
          severity: 9.2,
          title: 'EC2 instance is sending spam',
          description: 'Instance is being used to send spam emails',
          region: 'us-east-1',
          timestamp: new Date(Date.now() - 3600000).toISOString(),
          resource: { instanceId: 'i-0987654321fedcba0' },
          status: 'QUARANTINED'
        },
        {
          id: '3',
          type: 'Trojan:EC2/DriveBySourceTraffic',
          severity: 6.8,
          title: 'Suspicious network traffic detected',
          description: 'Unusual outbound traffic patterns detected',
          region: 'us-west-2',
          timestamp: new Date(Date.now() - 7200000).toISOString(),
          resource: { instanceId: 'i-abcdef1234567890' },
          status: 'ACTIVE'
        }
      ];

      setFindings(mockFindings);
      
      // Calculate stats
      const newStats = {
        total: mockFindings.length,
        critical: mockFindings.filter(f => f.severity >= 9).length,
        high: mockFindings.filter(f => f.severity >= 7 && f.severity < 9).length,
        medium: mockFindings.filter(f => f.severity >= 4 && f.severity < 7).length,
        low: mockFindings.filter(f => f.severity < 4).length
      };
      setStats(newStats);
      
    } catch (error) {
      console.error('Error fetching findings:', error);
    } finally {
      setLoading(false);
    }
  };

  const getSeverityColor = (severity) => {
    if (severity >= 9) return 'red';
    if (severity >= 7) return 'orange';
    if (severity >= 4) return 'yellow';
    return 'green';
  };

  const getSeverityText = (severity) => {
    if (severity >= 9) return 'CRITICAL';
    if (severity >= 7) return 'HIGH';
    if (severity >= 4) return 'MEDIUM';
    return 'LOW';
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'QUARANTINED': return 'red';
      case 'ACTIVE': return 'orange';
      case 'RESOLVED': return 'green';
      default: return 'default';
    }
  };

  const columns = [
    {
      title: 'Finding ID',
      dataIndex: 'id',
      key: 'id',
      width: 100,
    },
    {
      title: 'Type',
      dataIndex: 'type',
      key: 'type',
      width: 200,
      render: (type) => <Tag color="blue">{type}</Tag>
    },
    {
      title: 'Severity',
      dataIndex: 'severity',
      key: 'severity',
      width: 120,
      render: (severity) => (
        <Tag color={getSeverityColor(severity)}>
          {getSeverityText(severity)} ({severity})
        </Tag>
      ),
      sorter: (a, b) => a.severity - b.severity,
    },
    {
      title: 'Title',
      dataIndex: 'title',
      key: 'title',
      ellipsis: true,
    },
    {
      title: 'Instance ID',
      dataIndex: ['resource', 'instanceId'],
      key: 'instanceId',
      width: 150,
    },
    {
      title: 'Region',
      dataIndex: 'region',
      key: 'region',
      width: 100,
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      width: 120,
      render: (status) => <Tag color={getStatusColor(status)}>{status}</Tag>
    },
    {
      title: 'Timestamp',
      dataIndex: 'timestamp',
      key: 'timestamp',
      width: 180,
      render: (timestamp) => new Date(timestamp).toLocaleString(),
      sorter: (a, b) => new Date(a.timestamp) - new Date(b.timestamp),
    },
  ];

  const severityData = [
    { name: 'Critical', value: stats.critical, color: '#ff4d4f' },
    { name: 'High', value: stats.high, color: '#ff7a45' },
    { name: 'Medium', value: stats.medium, color: '#ffa940' },
    { name: 'Low', value: stats.low, color: '#52c41a' },
  ];

  const timelineData = [
    { time: '00:00', findings: 2 },
    { time: '04:00', findings: 1 },
    { time: '08:00', findings: 3 },
    { time: '12:00', findings: 1 },
    { time: '16:00', findings: 2 },
    { time: '20:00', findings: 1 },
  ];

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Header style={{ background: '#001529', color: 'white', padding: '0 24px' }}>
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <SecurityScanOutlined style={{ fontSize: '24px', marginRight: '16px' }} />
          <h1 style={{ color: 'white', margin: 0 }}>GuardDuty Security Dashboard</h1>
        </div>
      </Header>
      
      <Layout>
        <Sider width={300} style={{ background: '#f0f2f5', padding: '24px' }}>
          <Card title="Security Overview" size="small">
            <Row gutter={[16, 16]}>
              <Col span={12}>
                <Statistic
                  title="Total Findings"
                  value={stats.total}
                  prefix={<SecurityScanOutlined />}
                />
              </Col>
              <Col span={12}>
                <Statistic
                  title="Critical"
                  value={stats.critical}
                  valueStyle={{ color: '#ff4d4f' }}
                  prefix={<WarningOutlined />}
                />
              </Col>
              <Col span={12}>
                <Statistic
                  title="High"
                  value={stats.high}
                  valueStyle={{ color: '#ff7a45' }}
                />
              </Col>
              <Col span={12}>
                <Statistic
                  title="Medium"
                  value={stats.medium}
                  valueStyle={{ color: '#ffa940' }}
                />
              </Col>
            </Row>
          </Card>

          <Card title="Severity Distribution" size="small" style={{ marginTop: '16px' }}>
            <PieChart width={250} height={200}>
              <Pie
                data={severityData}
                cx={125}
                cy={100}
                innerRadius={40}
                outerRadius={80}
                paddingAngle={5}
                dataKey="value"
              >
                {severityData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </Card>
        </Sider>

        <Content style={{ padding: '24px' }}>
          <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
            <Col span={24}>
              <Alert
                message="Security Alert"
                description="Auto-quarantine is active for HIGH and CRITICAL severity findings. Monitor the dashboard for real-time security events."
                type="warning"
                showIcon
                closable
              />
            </Col>
          </Row>

          <Card title="Findings Timeline" style={{ marginBottom: '24px' }}>
            <LineChart width={800} height={300} data={timelineData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="time" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line type="monotone" dataKey="findings" stroke="#1890ff" strokeWidth={2} />
            </LineChart>
          </Card>

          <Card title="Security Findings" extra={<Spin spinning={loading} />}>
            <Table
              columns={columns}
              dataSource={findings}
              rowKey="id"
              pagination={{ pageSize: 10 }}
              scroll={{ x: 1200 }}
              size="small"
            />
          </Card>
        </Content>
      </Layout>
    </Layout>
  );
}

export default App;

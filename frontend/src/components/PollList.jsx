import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { pollAPI } from '../services/api';

const PollList = () => {
  const [polls, setPolls] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchPolls();
  }, []);

  const fetchPolls = async () => {
    try {
      const response = await pollAPI.getAllPolls();
      setPolls(response.data);
      setLoading(false);
    } catch (err) {
      setError('Failed to load polls');
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="loading">Loading polls...</div>;
  }

  if (error) {
    return <div className="error-message">{error}</div>;
  }

  return (
    <div className="poll-list-container">
      <div className="poll-list-header">
        <h2>All Polls</h2>
        <Link to="/create-poll" className="btn-primary">
          Create New Poll
        </Link>
      </div>

      {polls.length === 0 ? (
        <div className="empty-state">
          <p>No polls available yet.</p>
          <Link to="/create-poll" className="btn-primary">
            Create the first poll
          </Link>
        </div>
      ) : (
        <div className="poll-grid">
          {polls.map((poll) => (
            <Link to={`/polls/${poll.id}`} key={poll.id} className="poll-card">
              <h3>{poll.question}</h3>
              <div className="poll-meta">
                <span className="creator">by {poll.creatorUsername}</span>
                <span className="votes">{poll.totalVotes} votes</span>
              </div>
              <div className="poll-options-preview">
                {poll.options.slice(0, 3).map((option) => (
                  <div key={option.id} className="option-preview">
                    {option.text}
                  </div>
                ))}
                {poll.options.length > 3 && (
                  <div className="option-preview more">
                    +{poll.options.length - 3} more
                  </div>
                )}
              </div>
              {poll.expired && (
                <div className="expired-badge">Expired</div>
              )}
            </Link>
          ))}
        </div>
      )}
    </div>
  );
};

export default PollList;

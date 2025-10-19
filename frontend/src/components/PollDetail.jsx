import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { pollAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';

const PollDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();

  const [poll, setPoll] = useState(null);
  const [selectedOption, setSelectedOption] = useState(null);
  const [loading, setLoading] = useState(true);
  const [voting, setVoting] = useState(false);
  const [error, setError] = useState('');
  const [voteSuccess, setVoteSuccess] = useState(false);

  useEffect(() => {
    fetchPoll();
  }, [id]);

  const fetchPoll = async () => {
    try {
      const response = await pollAPI.getPollById(id);
      setPoll(response.data);
      setLoading(false);
    } catch (err) {
      setError('Failed to load poll');
      setLoading(false);
    }
  };

  const handleVote = async () => {
    if (!user) {
      navigate('/login');
      return;
    }

    if (!selectedOption) {
      setError('Please select an option');
      return;
    }

    setVoting(true);
    setError('');

    try {
      await pollAPI.vote(id, selectedOption);
      setVoteSuccess(true);
      // Refresh poll data to show updated vote counts
      await fetchPoll();
      setSelectedOption(null);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to cast vote');
    } finally {
      setVoting(false);
    }
  };

  const getPercentage = (voteCount) => {
    if (poll.totalVotes === 0) return 0;
    return ((voteCount / poll.totalVotes) * 100).toFixed(1);
  };

  if (loading) {
    return <div className="loading">Loading poll...</div>;
  }

  if (error && !poll) {
    return <div className="error-message">{error}</div>;
  }

  return (
    <div className="poll-detail-container">
      <button onClick={() => navigate('/')} className="btn-back">
        ← Back to Polls
      </button>

      <div className="poll-detail-card">
        <h2>{poll.question}</h2>

        <div className="poll-info">
          <span>Created by: <strong>{poll.creatorUsername}</strong></span>
          <span>Total Votes: <strong>{poll.totalVotes}</strong></span>
        </div>

        {poll.expired && (
          <div className="expired-banner">This poll has expired</div>
        )}

        {voteSuccess && (
          <div className="success-message">Vote cast successfully!</div>
        )}

        {error && <div className="error-message">{error}</div>}

        <div className="poll-options">
          {poll.options.map((option) => (
            <div
              key={option.id}
              className={`poll-option ${
                selectedOption === option.id ? 'selected' : ''
              }`}
              onClick={() => !poll.expired && setSelectedOption(option.id)}
            >
              <div className="option-header">
                <div className="option-radio">
                  {selectedOption === option.id && <div className="radio-dot" />}
                </div>
                <div className="option-text">{option.text}</div>
                <div className="option-count">{option.voteCount} votes</div>
              </div>

              <div className="option-bar-container">
                <div
                  className="option-bar"
                  style={{ width: `${getPercentage(option.voteCount)}%` }}
                />
              </div>

              <div className="option-percentage">
                {getPercentage(option.voteCount)}%
              </div>
            </div>
          ))}
        </div>

        {user && !poll.expired && (
          <button
            onClick={handleVote}
            className="btn-primary btn-vote"
            disabled={voting || !selectedOption}
          >
            {voting ? 'Voting...' : 'Cast Vote'}
          </button>
        )}

        {!user && !poll.expired && (
          <div className="login-prompt">
            <button onClick={() => navigate('/login')} className="btn-primary">
              Login to Vote
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default PollDetail;

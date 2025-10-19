import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { pollAPI } from '../services/api';

const CreatePoll = () => {
  const [question, setQuestion] = useState('');
  const [options, setOptions] = useState(['', '']);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const navigate = useNavigate();

  const handleOptionChange = (index, value) => {
    const newOptions = [...options];
    newOptions[index] = value;
    setOptions(newOptions);
  };

  const addOption = () => {
    setOptions([...options, '']);
  };

  const removeOption = (index) => {
    if (options.length > 2) {
      const newOptions = options.filter((_, i) => i !== index);
      setOptions(newOptions);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    // Validation
    const validOptions = options.filter((opt) => opt.trim() !== '');
    if (validOptions.length < 2) {
      setError('Please provide at least 2 options');
      return;
    }

    if (!question.trim()) {
      setError('Please provide a question');
      return;
    }

    setLoading(true);

    try {
      const pollData = {
        question: question.trim(),
        options: validOptions,
      };

      const response = await pollAPI.createPoll(pollData);
      navigate(`/polls/${response.data.id}`);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to create poll');
      setLoading(false);
    }
  };

  return (
    <div className="create-poll-container">
      <div className="create-poll-card">
        <h2>Create New Poll</h2>

        {error && <div className="error-message">{error}</div>}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Question</label>
            <input
              type="text"
              value={question}
              onChange={(e) => setQuestion(e.target.value)}
              placeholder="What's your question?"
              required
            />
          </div>

          <div className="form-group">
            <label>Options</label>
            {options.map((option, index) => (
              <div key={index} className="option-input-group">
                <input
                  type="text"
                  value={option}
                  onChange={(e) => handleOptionChange(index, e.target.value)}
                  placeholder={`Option ${index + 1}`}
                  required
                />
                {options.length > 2 && (
                  <button
                    type="button"
                    onClick={() => removeOption(index)}
                    className="btn-remove"
                  >
                    ×
                  </button>
                )}
              </div>
            ))}
            <button
              type="button"
              onClick={addOption}
              className="btn-secondary"
            >
              + Add Option
            </button>
          </div>

          <div className="form-actions">
            <button
              type="button"
              onClick={() => navigate('/')}
              className="btn-secondary"
            >
              Cancel
            </button>
            <button type="submit" className="btn-primary" disabled={loading}>
              {loading ? 'Creating...' : 'Create Poll'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CreatePoll;

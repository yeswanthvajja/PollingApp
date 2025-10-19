package com.polling.service;

import com.polling.dto.VoteRequest;
import com.polling.entity.Poll;
import com.polling.entity.PollOption;
import com.polling.entity.User;
import com.polling.entity.Vote;
import com.polling.repository.PollOptionRepository;
import com.polling.repository.PollRepository;
import com.polling.repository.UserRepository;
import com.polling.repository.VoteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class VoteService {

    @Autowired
    private VoteRepository voteRepository;

    @Autowired
    private PollRepository pollRepository;

    @Autowired
    private PollOptionRepository pollOptionRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public String castVote(Long pollId, VoteRequest voteRequest, String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Poll poll = pollRepository.findById(pollId)
                .orElseThrow(() -> new RuntimeException("Poll not found"));

        if (poll.getExpiresAt() != null && poll.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("This poll has expired");
        }

        if (voteRepository.findByUserIdAndPollId(user.getId(), pollId).isPresent()) {
            throw new RuntimeException("You have already voted in this poll");
        }

        PollOption pollOption = pollOptionRepository.findById(voteRequest.getOptionId())
                .orElseThrow(() -> new RuntimeException("Poll option not found"));

        if (!pollOption.getPoll().getId().equals(pollId)) {
            throw new RuntimeException("Invalid option for this poll");
        }

        Vote vote = new Vote();
        vote.setUser(user);
        vote.setPoll(poll);
        vote.setPollOption(pollOption);

        voteRepository.save(vote);

        return "Voted successfully!";
    }
}

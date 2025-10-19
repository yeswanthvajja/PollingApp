package com.polling.service;

import com.polling.dto.OptionResponse;
import com.polling.dto.PollRequest;
import com.polling.dto.PollResponse;
import com.polling.entity.Poll;
import com.polling.entity.PollOption;
import com.polling.entity.User;
import com.polling.repository.PollOptionRepository;
import com.polling.repository.PollRepository;
import com.polling.repository.UserRepository;
import com.polling.repository.VoteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class PollService {

    @Autowired
    private PollRepository pollRepository;

    @Autowired
    private PollOptionRepository pollOptionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private VoteRepository voteRepository;

    @Transactional
    public PollResponse createPoll(PollRequest pollRequest, String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Poll poll = new Poll();
        poll.setQuestion(pollRequest.getQuestion());
        poll.setCreator(user);
        poll.setExpiresAt(pollRequest.getExpiresAt());

        Poll savedPoll = pollRepository.save(poll);

        for (String optionText : pollRequest.getOptions()) {
            PollOption option = new PollOption();
            option.setText(optionText);
            option.setPoll(savedPoll);
            pollOptionRepository.save(option);
        }

        return convertToPollResponse(savedPoll);
    }

    public List<PollResponse> getAllPolls() {
        return pollRepository.findAllWithOptionsAndCreator().stream()
                .map(this::convertToPollResponse)
                .collect(Collectors.toList());
    }

    public PollResponse getPollById(Long pollId) {
        Poll poll = pollRepository.findByIdWithOptionsAndCreator(pollId)
                .orElseThrow(() -> new RuntimeException("Poll not found"));
        return convertToPollResponse(poll);
    }

    public List<PollResponse> getPollsByUser(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return pollRepository.findByCreatorIdWithOptions(user.getId()).stream()
                .map(this::convertToPollResponse)
                .collect(Collectors.toList());
    }

    private PollResponse convertToPollResponse(Poll poll) {
        List<OptionResponse> optionResponses = poll.getOptions().stream()
                .map(option -> {
                    Long voteCount = voteRepository.countByPollOptionId(option.getId());
                    return new OptionResponse(option.getId(), option.getText(), voteCount);
                })
                .collect(Collectors.toList());

        Long totalVotes = optionResponses.stream()
                .mapToLong(OptionResponse::getVoteCount)
                .sum();

        boolean isExpired = poll.getExpiresAt() != null && poll.getExpiresAt().isBefore(LocalDateTime.now());

        return new PollResponse(
                poll.getId(),
                poll.getQuestion(),
                poll.getCreator().getUsername(),
                optionResponses,
                totalVotes,
                poll.getCreatedAt(),
                poll.getExpiresAt(),
                isExpired
        );
    }
}

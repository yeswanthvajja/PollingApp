package com.polling.controller;

import com.polling.dto.ApiResponse;
import com.polling.dto.VoteRequest;
import com.polling.service.VoteService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/polls")
@CrossOrigin(origins = "*", maxAge = 3600)
public class VoteController {

    @Autowired
    private VoteService voteService;

    @PostMapping("/{pollId}/vote")
    public ResponseEntity<?> castVote(@PathVariable Long pollId,
                                      @Valid @RequestBody VoteRequest voteRequest,
                                      Authentication authentication) {
        try {
            String username = authentication.getName();
            String message = voteService.castVote(pollId, voteRequest, username);
            return ResponseEntity.ok(new ApiResponse(true, message));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse(false, "Error: " + e.getMessage()));
        }
    }
}

package com.polling.controller;

import com.polling.dto.ApiResponse;
import com.polling.dto.PollRequest;
import com.polling.dto.PollResponse;
import com.polling.service.PollService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/polls")
@CrossOrigin(origins = "*", maxAge = 3600)
public class PollController {

    @Autowired
    private PollService pollService;

    @PostMapping
    public ResponseEntity<?> createPoll(@Valid @RequestBody PollRequest pollRequest, 
                                        Authentication authentication) {
        try {
            String username = authentication.getName();
            PollResponse pollResponse = pollService.createPoll(pollRequest, username);
            return ResponseEntity.ok(pollResponse);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse(false, "Error: " + e.getMessage()));
        }
    }

    @GetMapping("/all")
    public ResponseEntity<List<PollResponse>> getAllPolls() {
        List<PollResponse> polls = pollService.getAllPolls();
        return ResponseEntity.ok(polls);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getPollById(@PathVariable Long id) {
        try {
            PollResponse pollResponse = pollService.getPollById(id);
            return ResponseEntity.ok(pollResponse);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse(false, "Error: " + e.getMessage()));
        }
    }

    @GetMapping("/user")
    public ResponseEntity<?> getUserPolls(Authentication authentication) {
        try {
            String username = authentication.getName();
            List<PollResponse> polls = pollService.getPollsByUser(username);
            return ResponseEntity.ok(polls);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(new ApiResponse(false, "Error: " + e.getMessage()));
        }
    }
}

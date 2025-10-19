package com.polling.repository;

import com.polling.entity.Vote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VoteRepository extends JpaRepository<Vote, Long> {
    Optional<Vote> findByUserIdAndPollId(Long userId, Long pollId);
    List<Vote> findByPollId(Long pollId);
    List<Vote> findByUserId(Long userId);
    
    @Query("SELECT COUNT(v) FROM Vote v WHERE v.pollOption.id = :optionId")
    Long countByPollOptionId(Long optionId);
}

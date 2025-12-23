package com.toolrent.msreports.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ToolRankingDTO {
    private Long toolId;
    private String toolName;
    private Long loanCount;
}

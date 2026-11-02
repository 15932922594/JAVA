package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.GameRecord;
import org.apache.ibatis.annotations.Mapper;

/** RANGE 训练场成绩 mapper */
@Mapper
public interface GameRecordMapper extends BaseMapper<GameRecord> {
}

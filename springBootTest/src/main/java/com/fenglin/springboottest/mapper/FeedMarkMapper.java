package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.FeedMark;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface FeedMarkMapper extends BaseMapper<FeedMark> {
}

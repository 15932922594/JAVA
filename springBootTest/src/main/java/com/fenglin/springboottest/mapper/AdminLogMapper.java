package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.AdminLog;
import org.apache.ibatis.annotations.Mapper;

/** 后台操作日志 Mapper */
@Mapper
public interface AdminLogMapper extends BaseMapper<AdminLog> {
}

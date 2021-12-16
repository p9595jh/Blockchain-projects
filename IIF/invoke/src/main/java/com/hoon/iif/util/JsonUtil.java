package com.hoon.iif.util;

import org.codehaus.jackson.map.ObjectMapper;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@Component
public class JsonUtil {

    public String toJsonString(Map<String, Object> map) {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(map);

        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
    }

    public String toFtcArgJsonString(Object... os) {
        Map<String, Object> map = new HashMap<>();
        map.put("args", os);
        return toJsonString(map);
    }
}

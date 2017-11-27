local cjson = require("cjson")

local type = type
local string_format = string.format
local string_find = string.find
local string_lower = string.lower
local ngx_re_find = ngx.re.find
local ngx_decode_base64 = ngx.decode_base64

local function assert_condition(real, operator, expected)
    if not real then
        ngx.log(ngx.ERR, string_format("assert_condition error: %s %s %s", real, operator, expected))
        return false
    end

    if operator == 'match' then
        if ngx_re_find(real, expected, 'isjo') ~= nil then
            return true
        end
    elseif operator == 'not_match' then
        if ngx_re_find(real, expected, 'isjo') == nil then
            return true
        end
    elseif operator == "=" then
        if real == expected then
            return true
        end
    elseif operator == "!=" then
        if real ~= expected then
            return true
        end
    elseif operator == '>' then
        if real ~= nil and expected ~= nil then
            expected = tonumber(expected)
            real = tonumber(real)
            if real and expected and real > expected then
                return true
            end
        end
    elseif operator == '>=' then
        if real ~= nil and expected ~= nil then
            expected = tonumber(expected)
            real = tonumber(real)
            if real and expected and real >= expected then
                return true
            end
        end
    elseif operator == '<' then
        if real ~= nil and expected ~= nil then
            expected = tonumber(expected)
            real = tonumber(real)
            if real and expected and real < expected then
                return true
            end
        end
    elseif operator == '<=' then
        if real ~= nil and expected ~= nil then
            expected = tonumber(expected)
            real = tonumber(real)
            if real and expected and real <= expected then
                return true
            end
        end
    end

    return false
end


local _M = {}

function _M.judge(condition)
    local condition_type = condition and condition.type
    if not condition_type then
        return false
    end

    local operator = condition.operator
    local expected = condition.value

    local real

    if condition_type == "URI" then
        real = ngx.var.uri
    elseif condition_type == "Query" then
        local query = ngx.req.get_uri_args()
        real = query[condition.name]
    elseif condition_type == "Header" then
        local headers = ngx.req.get_headers()
        real = headers[condition.name]
    elseif condition_type == "IP" then
        real =  ngx.var.remote_addr
    elseif condition_type == "UserAgent" then
        real =  ngx.var.http_user_agent
    elseif condition_type == "Method" then
        local method = ngx.req.get_method()
        method = string_lower(method)
        if not expected or type(expected) ~= "string" then
            expected = ""
        end
        expected = string_lower(expected)
        real = method
    elseif condition_type == "PostParams" then
        local headers = ngx.req.get_headers()
        local header = headers['Content-Type']
        if header then
            local is_multipart = string_find(header, "multipart")
            if is_multipart and is_multipart > 0 then
                return false
            end
        end

        ngx.req.read_body()
        local post_params, err = ngx.req.get_post_args()
        if not post_params or err then
            ngx.log(ngx.ERR, "[Condition Judge]failed to get post args: ", err)
            return false
        end

        real = post_params[condition.name]
    elseif condition_type == "Referer" then
        real =  ngx.var.http_referer
    elseif condition_type == "Host" then
        real =  ngx.var.host
    elseif condition_type == "JsonQueryParam" then
		local __get_query_content__ = ngx.req.__get_query_content__
		if __get_query_content__ == nil or type(__get_query_content__) ~= "function" then
			ngx.log(ngx.ERR, "[Condition Judge]failed to get json query content")
            return false
		end
		
        local __query_content__ = __get_query_content__()
		if type(__query_content__) == "table" then
			real = __query_content__[condition.name]
		elseif type(__query_content__) == "string" then
			local json_params = cjson.decode(__query_content__)
        		real = json_params[condition.name]
		else
			ngx.log(ngx.ERR, "[Condition Judge]invalid json query content type: ", type(__query_content__))
            return false
		end
		ngx.req.__get_query_content__ = nil
    elseif condition_type == "JsonPostParam" then
		local __get_post_content__ = ngx.req.__get_post_content__
		if __get_post_content__ ~= nil and type(__get_post_content__) == "function" then
			local __post_content__ = __get_post_content__()
			if type(__post_content__) == "table" then
				real = __post_content__[condition.name]
			elseif type(__post_content__) == "string" then
				local json_params = cjson.decode(__post_content__)
	        		real = json_params[condition.name]
			else
				ngx.log(ngx.ERR, "[Condition Judge]invalid json post content type: ", type(__post_content__))
	            return false
			end
		else
	        local headers = ngx.req.get_headers()
	        local header = headers['Content-Type']
	        if header then
	            local is_multipart = string_find(header, "multipart")
	            if is_multipart and is_multipart > 0 then
	                return false
	            end
	        end
	
	        ngx.req.read_body()
	        local post_body = ngx.req.get_body_data()
	        if not post_body then
	            ngx.log(ngx.ERR, "[Condition Judge]failed to get post body")
	            return false
	        end
	
	        local json_params = cjson.decode(post_body)
	        real = json_params[condition.name]
		end
		ngx.req.__get_post_content__ = nil
    elseif condition_type == "Base64QueryParam" then
		local __get_query_content__ = ngx.req.__get_query_content__
		if __get_query_content__ ~= nil and type(__get_query_content__) == "function" then
        		local __query_content__ = __get_query_content__()
			if type(__query_content__) == "table" then
				if __query_content__[condition.name] then
                    local b64_cipher = string.gsub(__query_content__[condition.name], " ", "+")
                    real = ngx_decode_base64(b64_cipher)
				else
                    real = nil
				end
			else
				ngx.log(ngx.ERR, "[Condition Judge]invalid base64 query content type: ", type(__query_content__))
	            return false
			end
		else
	        local query = ngx.req.get_uri_args()
	        if query[condition.name] then
                local b64_cipher = string.gsub(query[condition.name], " ", "+")
	            real = ngx_decode_base64(b64_cipher)
	        else
	            real = nil
	        end
		end
		ngx.req.__get_query_content__ = nil
    elseif condition_type == "Base64PostParam" then
		local __get_post_content__ = ngx.req.__get_post_content__
		if __get_post_content__ ~= nil and type(__get_post_content__) == "function" then
			local __post_content__ = __get_post_content__()
			if type(__post_content__) == "table" then
				if __post_content__[condition.name] then
                    local b64_cipher = string.gsub(__post_content__[condition.name], " ", "+")
                    real = ngx_decode_base64(b64_cipher)
				else
                    real = nil
				end
			else
				ngx.log(ngx.ERR, "[Condition Judge]invalid base64 query content type: ", type(__post_content__))
	            return false
			end
		else
	        local headers = ngx.req.get_headers()
	        local header = headers['Content-Type']
	        if header then
	            local is_multipart = string_find(header, "multipart")
	            if is_multipart and is_multipart > 0 then
	                return false
	            end
	        end
	
	        ngx.req.read_body()
	        local post_params, err = ngx.req.get_post_args()
	        if not post_params or err then
	            ngx.log(ngx.ERR, "[Condition Judge]failed to get post args: ", err)
	            return false
	        end
	
	        if post_params[condition.name] then
                local b64_cipher = string.gsub(post_params[condition.name], " ", "+")
	            real = ngx_decode_base64(b64_cipher)
	        else
	            real = nil
	        end
		end
		ngx.req.__get_post_content__ = nil
    elseif condition_type == "B64DecQueryParam" then
		local __get_query_content__ = ngx.req.__get_query_content__
		if __get_query_content__ ~= nil and type(__get_query_content__) == "function" then
        		local __query_content__ = __get_query_content__()
			if type(__query_content__) == "table" then
				if __query_content__[condition.name] then
                    local b64_cipher = string.gsub(__query_content__[condition.name], " ", "+")
                    local b64_plain = ngx_decode_base64(b64_cipher)
                    ngx.req.__get_query_content__ = function ()
                        return b64_plain
                    end
				else
                    return false
				end
			elseif type(__query_content__) == "string" then
				if condition.name == nil or condition.name == "" then
                    local b64_cipher = string.gsub(__query_content__, " ", "+")
                    local b64_plain = ngx_decode_base64(b64_cipher)
                    ngx.req.__get_query_content__ = function ()
                        return b64_plain
                    end
				else
		            ngx.log(ngx.ERR, "[Condition Judge]invalid base64 query content")
		            return false
				end
			else
				ngx.log(ngx.ERR, "[Condition Judge]invalid base64 query content type: ", type(__query_content__))
	            return false
			end
		else
	        local query = ngx.req.get_uri_args()
	        if query[condition.name] then
                local b64_cipher = string.gsub(query[condition.name], " ", "+")
	            local b64_plain = ngx_decode_base64(b64_cipher)
				ngx.req.__get_query_content__ = function ()
                    return b64_plain
				end
	        else
				ngx.log(ngx.ERR, "[Condition Judge]invalid base64 query name: ", condition.name)
	            return false
	        end
		end
		return true
    end

    return assert_condition(real, operator, expected)
end


return _M

function qb
    if ss -tln | grep -q ':1081 '
        env http_proxy=http://127.0.0.1:1081 https_proxy=http://127.0.0.1:1081 qutebrowser
    else
        qutebrowser
    end
end

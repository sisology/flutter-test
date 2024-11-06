import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { JWT } from 'npm:google-auth-library@9';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const fcmServiceAccount = JSON.parse(Deno.env.get('FCM_SERVER_KEY') ?? '');

const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

async function getAccessToken() {
    const jwtClient = new JWT({
        email: fcmServiceAccount.client_email,
        key: fcmServiceAccount.private_key,
        scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });

    return new Promise((resolve, reject) => {
        jwtClient.authorize((err, tokens) => {
            if (err) {
                reject(err);
                return;
            }
            resolve(tokens.access_token);
        });
    });
}

async function sendFCMMessage(token: string, title: string, body: string) {
    const accessToken = await getAccessToken();
    const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${fcmServiceAccount.project_id}/messages:send`,
        {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${accessToken}`,
            },
            body: JSON.stringify({
                message: {
                    token: token,
                    notification: {
                        title: title,
                        body: body,
                    },
                },
            }),
        }
    );

    if (!response.ok) {
        throw new Error(`FCM request failed: ${await response.text()}`);
    }

    return await response.json();
}

serve(async (req) => {
    const payload = await req.json();
    const now = new Date();
    const currentTime = now.toISOString().slice(11, 16); // HH:MM 형식

    console.log(`Current server time (UTC): ${currentTime}`);
    console.log(`Payload: `, JSON.stringify(payload));

    let users;
    if (payload.type === 'CRON' || payload.type === 'UPDATE') {
        // 알람 시간과 비교할 시간 범위 설정 (예: ±1분)
        const currentMinute = parseInt(currentTime.split(":")[1]);
        const lowerBound = `${currentTime.split(":")[0]}:${(currentMinute - 1).toString().padStart(2, '0')}`;
        const upperBound = `${currentTime.split(":")[0]}:${(currentMinute + 1).toString().padStart(2, '0')}`;

        console.log(`Comparing between ${lowerBound} and ${upperBound}`);

        const { data, error } = await supabase
            .from('member')
            .select('member_id, alarm_time')
            .eq('alarm_enabled', true)
            .gte('alarm_time', lowerBound)
            .lte('alarm_time', upperBound);

        if (error) {
            console.error('Error fetching users:', error);
            return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500 });
        }

        users = data;
        console.log(`Fetched users: `, JSON.stringify(users));
    } else {
        console.log(`Unknown payload type: ${payload.type}`);
        users = [];
    }

    console.log(`Found ${users.length} users with active alarms`);

    // 알림 전송 로직
    for (const user of users) {
        const { data: tokens, error: tokenError } = await supabase
            .from('fcm_tokens')
            .select('token')
            .eq('member_id', user.member_id);

        if (tokenError) {
            console.error('Error fetching FCM token:', tokenError);
            continue;
        }

        if (tokens && tokens.length > 0) {
            try {
                const response = await sendFCMMessage(
                    tokens[0].token,
                    '일기쓸 시간이에요',
                    '오늘 하루는 어땠나요? 일기를 작성해보세요.'
                );
                console.log(`Notification sent successfully to member_id: ${user.member_id}`);
            } catch (error) {
                console.error('Error sending FCM message:', error);
            }
        } else {
            console.log(`No FCM token found for member_id: ${user.member_id}`);
        }
    }

    return new Response(JSON.stringify({ success: true, notificationsSent: users.length }), { status: 200 });
});
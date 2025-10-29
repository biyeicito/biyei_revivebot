Config = {}

Config.Framework = 'auto' -- 'auto', 'esx', 'qbcore'

Config.MedicsJobs = { 'ambulance' }

Config.EventRevive = 'wasabi_ambulance:revive'

Config.UseTarget = true -- Use target to interact with the bot
Config.Target = 'ox_target' -- 'ox_target', 'qb-target'


Config.Bots = {
    {
        jobs = { 'police' }, -- Set to false to allow any job or { 'police', 'ambulance' } to allow specific jobs
        citizenid = false, -- Set to false to allow any citizenid or { '1234567890', '1234567891', '1234567892' } to allow specific citizenids
        model = 's_m_m_doctor_01',
        minMedics = 1,
        coords = vector4(-1889.2802, 3256.8298, 32.8431, 65.9564),
        secondsToRevive = 10, 
    }
}


using PyCall;
@pyimport neopixel
LED_COUNT      = 300      # Number of LED pixels.
LED_PIN        = 18      # GPIO pin connected to the pixels (must support PWM!).
LED_FREQ_HZ    = 800000  # LED signal frequency in hertz (usually 800khz)
LED_DMA        = 5       # DMA channel to use for generating signal (try 5)
LED_BRIGHTNESS = 255     # Set to 0 for darkest and 255 for brightest
LED_INVERT     = false   # True to invert the signal (when using NPN transistor level shift)
function num2byteA{T<:Union{Float16, Float32, Float64, Signed, Unsigned}}(x::T)
    bitstring = bits(x)
    return [parse(UInt8, bitstring[i:i+7], 2) for i in 1:8:length(bitstring)]
end
function clearLights(ledstrip)
    setAllLightsRGB(ledstrip, 0,0,0)
end
function setAllLightsRGB(ledstrip, R, G, B)
    for i in 1:LED_COUNT
        setColorRGB(ledstrip, i, R,G,B)
    end
    ledstrip[:show]()
end
function serverInfo()
    #=
    uint8_t mac_address[6];
    uint8_t ip_address[4];
    uint8_t device_type;
    uint8_t protocol_version; // for the device, not the discovery
    uint16_t vendor_id;
    uint16_t product_id;
    uint16_t hw_revision;
    uint16_t sw_revision;
    uint32_t link_speed;  // in bits per second
    =#
    macString = readstring(`cat /sys/class/net/eth0/address`)
    ipString = split(readstring(`hostname -I`))[1]
    macs = split(macString, ":")
    mac = [parse(UInt8, "0x"*macs[i]) for i in eachindex(macs)]
    ips = split(ipString, ".")
    ip = [parse(UInt8, "0x"*ips[i]) for i in eachindex(ips)]
    deviceType::UInt8 = 0
    protocolVersion::UInt8 = 1
    vendorID::UInt16 = 1996
    vID = num2byteA(vendorID)
    productID::UInt16 = 56472
    pID = num2byteA(productID)
    hardwareRevision::UInt16 = 42
    hRev = num2byteA(hardwareRevision)
    softwareRevision::UInt16 = 999
    sRev = num2byteA(softwareRevision)
    linkSpeed::UInt32 = 100000000
    lSpeed = num2byteA(linkSpeed)
    package = [mac..., ip..., deviceType, protocolVersion, vID..., pID..., hRev..., sRev..., lSpeed...]
    return package
end
function parseAndUpdate(ledstrip, rawData::Array{UInt8,1})
    dataRange = 1:3:length(rawData)-1
    output = [zeros(UInt8,3) for i in 1:length(dataRange)]
    j=0
    for i in dataRange
        vals = rawData[i:i+2]
        val1 = vals[1]
        val2 = vals[2]
        val3 = vals[3]
        j+=1
        #val2 = convert(Int32, "0x"*rawData[3:4])
        #val3 = convert(Int32, "0x"*rawData[5:6])
        output[j] = [val1, val2, val3]
    end
    updateLEDs(ledstrip, output)
end
function updateLEDs(ledstrip, ledData::Array{Array{UInt8, 1}, 1})
    for i in eachindex(ledData)
        setColorRGB(ledstrip, i, ledData[i]...)
        #setColorRGB(ledstrip, i, ledData[i]...)
    end
    ledstrip[:show]()
end
function setColorRGB(ledstrip, i, R, G, B)
    ledstrip[:setPixelColorRGB](i-1, G, R, B)
end
function openHardware()
    # LED strip configuration:
    ledstrip = neopixel.Adafruit_NeoPixel(LED_COUNT, LED_PIN, LED_FREQ_HZ, LED_DMA, LED_INVERT, LED_BRIGHTNESS)
    ledstrip[:begin]()
    return ledstrip
end
function main()
    #server = listen(IPv4(0), 8080)
    ledstrip = openHardware()
    clearLights(ledstrip)
    try
        #=
        while true
            socket = accept(server)
            write(socket, serverInfo())
            println(serverInfo())
            @async while isopen(socket)
                parseAndUpdate(readline(socket))
            end
        end
        =#
        udpsock = UDPSocket()
        bind(udpsock,ip"0.0.0.0",8080)
        for i in 1:10
            if i % 1 == 0
                setAllLightsRGB(ledstrip, 255, 0,0)
            end
            send(udpsock, ip"10.42.0.1", 8080, serverInfo())
            sleep(1)
            clearLights()
        end
        while true
            parseAndUpdate(ledstrip, recv(udpsock))
        end
    catch ex
        println("Caught An Exception")
        println(typeof(ex))
        if isa(ex, InterruptException)
            println("Program Terminated Successfully")
        end
    end
end

println("Server Listening on port 8080, use <Ctrl>-C to end the program.")
main()

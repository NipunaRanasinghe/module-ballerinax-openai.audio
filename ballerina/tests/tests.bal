// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
  
import ballerina/test;
import ballerina/mime; 
import ballerina/io;
import ballerina/os;

configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
configurable string token = isLiveServer ? os:getEnv("OPENAI_API_KEY") : "test";
configurable string serviceUrl = isLiveServer ? "https://api.openai.com/v1" : "http://localhost:9090";


final ConnectionConfig config = {
    auth: {
        token
    }
};
final Client openAIAudio = check new(config,serviceUrl);

const AUDIO_FILE_PATH1 = "tests/resources/audioClip.mp3";

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function  testCreateTranslation() returns error? {

    byte[] audioContent = check io:fileReadBytes(AUDIO_FILE_PATH1);

    CreateTranslationRequest payload = {
        file: {
            fileContent: audioContent, fileName: "speech.mp3"},
            model: "whisper-1"
    };
    CreateTranslationResponse result = check openAIAudio->/audio/translations.post(payload);
    test:assertEquals(result.text, "The");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function  testCreateSpeech() returns error? {
    CreateSpeechRequest requestPayload = {
        model: "tts-1",
        input: "The",
        voice: "alloy",
        response_format: "mp3",
        speed: 1.0
     };
    byte[] response = check openAIAudio->/audio/speech.post(requestPayload);
    test:assertTrue(response.length() > 2000, msg = "Expected response length to be greater than 2000, but found " + response.length().toString());
}


@test:Config {
    enable:false,
    groups: ["live_tests", "mock_tests"]
}
isolated function  testCreateTranscription() returns error? {  
    byte[] audioContent = check io:fileReadBytes(AUDIO_FILE_PATH1);

   CreateTranscriptionRequest payload = {
       file: {fileContent: audioContent, fileName: "./speech.mp3"},
       model: "whisper-1"
    };
    map<string> headers = {
       "Content-Type": mime:MULTIPART_FORM_DATA
   };
    CreateTranscriptionResponse result = check openAIAudio->/audio/transcriptions.post(payload, headers);
    test:assertEquals(result.text, "The");
}


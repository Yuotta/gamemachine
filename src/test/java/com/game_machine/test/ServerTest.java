package com.game_machine.test;

import static org.fest.assertions.api.Assertions.assertThat;
import java.util.logging.Logger;

import org.testng.annotations.AfterClass;
import org.testng.annotations.AfterSuite;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.BeforeSuite;
import org.testng.annotations.Test;

import com.game_machine.Config;
import com.game_machine.GameMachine;
import com.game_machine.NetMessage;
import com.game_machine.ProtobufMessages.ClientMessage;
import com.game_machine.net.client.ClientCallable;
import com.game_machine.net.client.UdpClient;
import com.game_machine.net.client.UdtClient;

public class ServerTest {

	public static final Logger log = Logger.getLogger(ServerTest.class.getName());

	@BeforeSuite
	public void setup() {
		GameMachine.start();
	}

	@AfterSuite
	public void teardown() {
		GameMachine.stop();
	}

	@Test
	public void UdpEcho() {
		final UdpClient client = new UdpClient(NetMessage.ENCODING_PROTOBUF, Config.udpHost, Config.udpPort);

		client.setCallback(new ClientCallable() {
			public void apply(Object obj) {
				ClientMessage message = (ClientMessage) obj;
				String body = message.getBody().toStringUtf8();
				if (body.equals("READY")) {
					client.send("STOP".getBytes());
				} else {
					assertThat(body).isEqualTo("STOP");
					client.stop();
				}
			}
		});
		client.start();

	}

	@Test
	public void udtEcho() {
		final UdtClient client = new UdtClient(NetMessage.ENCODING_PROTOBUF, Config.udtHost, Config.udtPort);

		client.setCallback(new ClientCallable() {
			public void apply(Object obj) {
				ClientMessage message = (ClientMessage) obj;
				String body = message.getBody().toStringUtf8();
				if (body.equals("READY")) {
					client.send("STOP".getBytes());
				} else {
					assertThat(body).isEqualTo("STOP");
					client.stop();
				}
			}
		});
		client.start();
	}

}
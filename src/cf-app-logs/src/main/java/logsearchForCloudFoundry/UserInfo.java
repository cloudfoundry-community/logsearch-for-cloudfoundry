package logsearchForCloudFoundry;

import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public class UserInfo {

	@JsonProperty("user_id")
	protected String user_id;
    @JsonProperty("user_name")
	protected String user_name;
    @JsonProperty("email")
	protected String email;
   
    public UUID getUserId() {
        return UUID.fromString(this.user_id);
    }

    public String getUserName() {
        return this.user_name;
    }

    public String getEmail() {
        return this.email;
    }

}

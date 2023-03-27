public class HelloWorld {

	public String getMessage() {
		return "Hello World!";
	}

	String getOtherMessage() {
		return "Hello Other World!";
	}

	public static void main(String[] args) {
		HelloWorld helloWorld = new HelloWorld();
		System.out.println(helloWorld.getMessage());
	}
}

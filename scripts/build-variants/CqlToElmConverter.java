import org.cqframework.cql.cql2elm.*;
import org.cqframework.cql.elm.execution.Library;
import org.hl7.elm.r1.VersionedIdentifier;

import java.io.*;
import java.nio.file.*;
import java.util.*;

public class CqlToElmConverter {
    public static void main(String[] args) {
        if (args.length < 2) {
            System.out.println("Usage: java CqlToElmConverter <input.cql> <output.json>");
            System.exit(1);
        }
        
        String inputPath = args[0];
        String outputPath = args[1];
        
        try {
            // Read CQL file
            String cqlContent = new String(Files.readAllBytes(Paths.get(inputPath)));
            
            // Create CQL to ELM translator
            ModelManager modelManager = new ModelManager();
            LibraryManager libraryManager = new LibraryManager(modelManager);
            CqlTranslator translator = CqlTranslator.fromText(cqlContent, modelManager, libraryManager);
            
            // Check for errors
            if (translator.getErrors().size() > 0) {
                System.err.println("Translation errors:");
                for (CqlTranslatorException error : translator.getErrors()) {
                    System.err.println(error.getMessage());
                }
                System.exit(1);
            }
            
            // Convert to JSON
            String elmJson = translator.toJson();
            
            // Write output
            Files.write(Paths.get(outputPath), elmJson.getBytes());
            
            System.out.println("Success: " + outputPath);
            
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}
